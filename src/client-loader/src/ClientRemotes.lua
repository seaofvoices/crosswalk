local getFireRemote = require('./getFireRemote')

local Common = require('@pkg/crosswalk-common')
local Reporter = Common.Reporter

type RemoteInformation = Common.RemoteInformation
type Reporter = Common.Reporter

export type ClientRemotes = {
    listen: (self: ClientRemotes) -> (),
    disconnect: (self: ClientRemotes) -> (),
    getServerModules: (self: ClientRemotes) -> { [string]: { [string]: (...any) -> any } },
    connectRemote: (
        self: ClientRemotes,
        module: string,
        functionName: string,
        callback: () -> ()
    ) -> (),
    fireReadyRemote: (self: ClientRemotes) -> (),
}

type Private = {
    remotesSetup: boolean,
    remotes: { [string]: { [string]: RemoteEvent | RemoteFunction } },
    currentKeys: { [string]: { [string]: string } },
    waitForKeyNames: { [string]: { [string]: true } },
    yieldNames: { [string]: { [string]: true } },
    serverModules: { [string]: { [string]: (...any) -> any } },
    connections: { () -> () },
    remotesParent: Instance,
    reporter: Reporter,

    _processServerInfo: (self: ClientRemotes, info: RemoteInformation) -> (),
    _getFireRemote: (
        self: ClientRemotes,
        module: string,
        functionName: string,
        remote: RemoteEvent | RemoteFunction,
        withKey: boolean
    ) -> (...any) -> any,
    _yieldUntilNewKey: (self: ClientRemotes, module: string, functionName: string) -> (),
    _getRemotes: (self: ClientRemotes) -> Instance,
    _waitForRemoteSetup: (self: ClientRemotes, initialLabel: string, callLabel: string) -> (),
}

type NewClientRemotesOptions = {
    remotesParent: Instance,
    reporter: Reporter?,
}

type ClientRemotesStatic = ClientRemotes & Private & {
    new: (NewClientRemotesOptions) -> ClientRemotes,
}

local ClientRemotes: ClientRemotesStatic = {} :: any
local ClientRemotesMetatable = {
    __index = ClientRemotes,
}

function ClientRemotes:listen()
    local self = self :: ClientRemotes & Private

    local remoteObjects = self:_getRemotes():GetChildren()

    for _, remote in remoteObjects do
        if remote.Name:match('^[^ ]*  $') and remote:IsA('RemoteFunction') then
            task.spawn(function()
                self.reporter:debug('invoking server for remote information')
                local data = remote:InvokeServer()
                self.reporter:debug('received remote information')
                self:_processServerInfo(data)
            end)
        elseif remote.Name:match('^[^ ]*   $') and remote:IsA('RemoteEvent') then
            local connection = remote.OnClientEvent:Connect(function(newKey, moduleName, funcName)
                self.currentKeys[moduleName][funcName] = newKey
                self.yieldNames[moduleName][funcName] = nil
            end)
            table.insert(self.connections, function()
                connection:Disconnect()
            end)
        end
    end
end

function ClientRemotes:disconnect()
    local self = self :: ClientRemotes & Private

    for _, disconnect in self.connections do
        disconnect()
    end
    self.connections = {}
end

function ClientRemotes:getServerModules()
    local self = self :: ClientRemotes & Private

    return self.serverModules
end

function ClientRemotes:connectRemote(module, functionName, callback)
    local self = self :: ClientRemotes & Private

    self:_waitForRemoteSetup(
        ('attempt to connect remote before server has sent required information (`%s.%s`)'):format(
            module,
            functionName
        ),
        'connectRemote'
    )

    self.reporter:assert(
        self.remotes[module] ~= nil,
        'unable to find remotes for module `%s`',
        module
    )
    local remote = self.remotes[module][functionName]
    self.reporter:assert(remote ~= nil, 'unable to find remote for `%s.%s`', module, functionName)

    if remote:IsA('RemoteEvent') then
        local connection = remote.OnClientEvent:Connect(callback)
        table.insert(self.connections, function()
            connection:Disconnect()
        end)
    else
        remote.OnClientInvoke = callback
        table.insert(self.connections, function()
            remote.OnClientInvoke = nil :: any
        end)
    end
end

function ClientRemotes:fireReadyRemote()
    local self = self :: ClientRemotes & Private

    self:_waitForRemoteSetup(
        'attempt to send ready notification before receiving server information',
        'fireReadyRemote'
    )

    local remotes = self:_getRemotes()
    for _, remote in remotes:GetChildren() do
        if remote.Name:match('^[^ ]*    $') and remote:IsA('RemoteEvent') then
            remote:FireServer()
            return
        end
    end
    self.reporter:error('failed to report ready status to server (cannot find remote)')
end

function ClientRemotes:_processServerInfo(data: RemoteInformation)
    local self = self :: ClientRemotes & Private

    local remoteFolder = self:_getRemotes()

    self.currentKeys = data.Keys
    self.waitForKeyNames = data.WaitForKeyNames

    for moduleName, functions in data.Names do
        self.remotes[moduleName] = {}

        if data.NameServerMap[moduleName] then
            self.serverModules[moduleName] = {}
            self.yieldNames[moduleName] = {}

            for functionName, id in functions do
                local remote = remoteFolder:WaitForChild(id) :: RemoteEvent | RemoteFunction
                self.remotes[moduleName][functionName] = remote

                self.serverModules[moduleName][functionName] = self:_getFireRemote(
                    moduleName,
                    functionName,
                    remote,
                    self.currentKeys[moduleName][functionName] ~= nil
                )
            end
        else
            for functionName, id in functions do
                self.remotes[moduleName][functionName] =
                    remoteFolder:WaitForChild(id) :: RemoteEvent | RemoteFunction
            end
        end
    end
    self.remotesSetup = true
end

function ClientRemotes:_getFireRemote(
    module: string,
    functionName: string,
    remote: RemoteEvent | RemoteFunction,
    withKey: boolean
): (...any) -> any
    local self = self :: ClientRemotes & Private

    if not withKey then
        return getFireRemote(remote, nil)
    end

    if not self.waitForKeyNames[module][functionName] then
        local key = self.currentKeys[module][functionName]
        return getFireRemote(remote, key)
    end

    local yieldModule = self.yieldNames[module]
    local isEvent = remote:IsA('RemoteEvent')

    local function fireRemote(...)
        if yieldModule[functionName] then
            self.reporter:warn(
                'call to `%s.%s` skipped because client did not receive a new key yet',
                module,
                functionName
            )
            return
        end

        yieldModule[functionName] = true

        if isEvent then
            (remote :: RemoteEvent):FireServer(self.currentKeys[module][functionName], ...)
            self:_yieldUntilNewKey(module, functionName)
            return
        else
            local result = table.pack(
                (remote :: RemoteFunction):InvokeServer(self.currentKeys[module][functionName], ...)
            )
            self:_yieldUntilNewKey(module, functionName)
            return unpack(result, 1, result.n)
        end
    end

    return fireRemote
end

function ClientRemotes:_yieldUntilNewKey(module: string, functionName: string)
    local self = self :: ClientRemotes & Private

    repeat
        task.wait()
    until not self.yieldNames[module][functionName]
end

function ClientRemotes:_getRemotes(): Instance
    local self = self :: ClientRemotes & Private

    return self.remotesParent:WaitForChild('Remotes')
end

function ClientRemotes:_waitForRemoteSetup(initialLabel: string, callLabel: string)
    local self = self :: ClientRemotes & Private

    if not self.remotesSetup then
        self.reporter:debug(initialLabel)
        repeat
            task.wait()
        until self.remotesSetup
        self.reporter:debug('remote setup completed, resuming `%s` call', callLabel)
    end
end

function ClientRemotes.new(options: NewClientRemotesOptions): ClientRemotes
    return setmetatable({
        remotesSetup = false,
        remotes = {},
        currentKeys = {},
        waitForKeyNames = {},
        yieldNames = {},
        serverModules = {},
        connections = {},
        remotesParent = options.remotesParent,
        reporter = options.reporter or Reporter.default(),
    }, ClientRemotesMetatable) :: any
end

return ClientRemotes
