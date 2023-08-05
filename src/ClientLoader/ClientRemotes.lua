local Reporter = require('../Common/Reporter')
local getFireRemote = require('./getFireRemote')

local ClientRemotes = {}
local ClientRemotesMetatable = { __index = ClientRemotes }

function ClientRemotes:listen()
    local remoteObjects = self:_getRemotes():GetChildren()

    for _, remote in ipairs(remoteObjects) do
        if remote.Name:match('^[^ ]*  $') then
            task.spawn(function()
                self.reporter:debug('invoking server for remote information')
                local data = remote:InvokeServer()
                self.reporter:debug('received remote information')
                self:_processServerInfo(data)
            end)
        elseif remote.Name:match('^[^ ]*   $') then
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
    for _, disconnect in ipairs(self.connections) do
        disconnect()
    end
    self.connections = {}
end

function ClientRemotes:getServerModules()
    return self.serverModules
end

function ClientRemotes:connectRemote(module, functionName, callback)
    if not self.remotesSetup then
        self.reporter:debug(
            'attempt to connect remote before server has sent required information (`%s.%s`)',
            module,
            functionName
        )
        repeat
            task.wait()
        until self.remotesSetup
        self.reporter:debug('remote setup completed, resuming `connectRemote` call')
    end

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
            remote.OnClientInvoke = nil
        end)
    end
end

function ClientRemotes:fireReadyRemote()
    local remotes = self:_getRemotes()
    for _, remote in ipairs(remotes:GetChildren()) do
        if remote.Name:match('^[^ ]*    $') then
            remote:FireServer()
            return
        end
    end
    self.reporter:error('failed to report ready status to server (cannot find remote)')
end

function ClientRemotes:_processServerInfo(data)
    local remoteFolder = self:_getRemotes()

    self.currentKeys = data.Keys
    self.waitForKeyNames = data.WaitForKeyNames

    for moduleName, functions in pairs(data.Names) do
        self.remotes[moduleName] = {}

        if data.NameServerMap[moduleName] then
            self.serverModules[moduleName] = {}
            self.yieldNames[moduleName] = {}

            for functionName, id in pairs(functions) do
                local remote = remoteFolder:WaitForChild(id)
                self.remotes[moduleName][functionName] = remote

                self.serverModules[moduleName][functionName] = self:_getFireRemote(
                    moduleName,
                    functionName,
                    remote,
                    self.currentKeys[moduleName][functionName] ~= nil
                )
            end
        else
            for functionName, id in pairs(functions) do
                self.remotes[moduleName][functionName] = remoteFolder:WaitForChild(id)
            end
        end
    end
    self.remotesSetup = true
end

function ClientRemotes:_getFireRemote(module, functionName, remote, withKey)
    if not withKey then
        return getFireRemote(remote)
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
            remote:FireServer(self.currentKeys[module][functionName], ...)
            self:_yieldUntilNewKey(module, functionName)
        else
            local result =
                table.pack(remote:InvokeServer(self.currentKeys[module][functionName], ...))
            self:_yieldUntilNewKey(module, functionName)
            return unpack(result, 1, result.n)
        end
    end

    return fireRemote
end

function ClientRemotes:_yieldUntilNewKey(module, functionName)
    repeat
        task.wait()
    until not self.yieldNames[module][functionName]
end

function ClientRemotes:_getRemotes()
    return self.remotesParent:WaitForChild('Remotes')
end

local function new(options)
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
    }, ClientRemotesMetatable)
end

return {
    new = new,
}
