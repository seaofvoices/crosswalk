local Players = game:GetService('Players')

local Map2D = require('./Map2D')
type Map2D<T, U, V> = Map2D.Map2D<T, U, V>
local RemoteStorage = require('./RemoteStorage')
type RemoteStorage = RemoteStorage.RemoteStorage
local KeyStorage = require('./KeyStorage')
type KeyStorage = KeyStorage.KeyStorage
local Reporter = require('../Common/Reporter')
type Reporter = Reporter.Reporter
local RemoteInformation = require('../Common/RemoteInformation')
type RemoteInformation = RemoteInformation.RemoteInformation

type RemoteSecurity = 'None' | 'Low' | 'High'

export type ServerRemotes = {
    addEventToClient: <Args...>(
        self: ServerRemotes,
        moduleName: string,
        functionName: string
    ) -> ((Player, Args...) -> (), (Args...) -> ()),
    addFunctionToClient: (
        self: ServerRemotes,
        moduleName: string,
        functionName: string
    ) -> (
        (Player, ...any) -> any,
        (...any) -> (boolean, { [Player]: { [number]: any, n: number } })
    ),
    addEventToServer: <Args...>(
        self: ServerRemotes,
        moduleName: string,
        functionName: string,
        func: (Player, Args...) -> boolean,
        security: RemoteSecurity?
    ) -> (),
    addFunctionToServer: <T..., U...>(
        self: ServerRemotes,
        moduleName: string,
        functionName: string,
        func: (Player, T...) -> (boolean, U...),
        security: RemoteSecurity?
    ) -> (),
    getRemoteInformation: (self: ServerRemotes, player: Player) -> RemoteInformation,
    setOnUnapprovedExecution: (
        self: ServerRemotes,
        callback: (Player, moduleName: string, functionName: string) -> ()
    ) -> (),
    clearPlayer: (self: ServerRemotes, player: Player) -> (),
}

type Private = {
    nameServerMap: { [string]: boolean },
    remotesToClient: Map2D<string, string, RemoteEvent | RemoteFunction>,
    remotesToServer: Map2D<string, string, RemoteEvent | RemoteFunction>,
    remoteSecurity: Map2D<string, string, RemoteSecurity>,
    onUnapprovedExecution: (Player, moduleName: string, functionName: string) -> (),
    isPlayerReady: (Player) -> boolean,
    remoteStorage: RemoteStorage,
    keyStorage: KeyStorage,
    remoteCallMaxDelay: number,
    playersService: Players,
    reporter: Reporter,
}

type NewServerRemotesOptions = {
    isPlayerReady: (Player) -> boolean,
    remoteStorage: RemoteStorage,
    keyStorage: KeyStorage,
    remoteCallMaxDelay: number?,
    reporter: Reporter?,
    playersService: Players?,
}

type ServerRemotesStatic = ServerRemotes & Private & {
    new: (NewServerRemotesOptions) -> ServerRemotes,
}

local ServerRemotes: ServerRemotesStatic = {} :: any
local ServerRemotesMetatable = {
    __index = ServerRemotes,
}

function ServerRemotes.new(options: NewServerRemotesOptions): ServerRemotes
    return setmetatable({
        nameServerMap = {},
        remotesToClient = Map2D.new(),
        remotesToServer = Map2D.new(),
        remoteSecurity = Map2D.new(),
        onUnapprovedExecution = function(_player, _module, _name) end,
        isPlayerReady = options.isPlayerReady,
        remoteStorage = options.remoteStorage,
        keyStorage = options.keyStorage,
        remoteCallMaxDelay = options.remoteCallMaxDelay or 2,
        playersService = options.playersService or Players,
        reporter = options.reporter or Reporter.default(),
    }, ServerRemotesMetatable) :: any
end

function ServerRemotes:addEventToClient<Args...>(
    moduleName: string,
    functionName: string
): ((Player, Args...) -> (), (Args...) -> ())
    local self = self :: ServerRemotes & Private
    self.nameServerMap[moduleName] = false

    local remote = self.remoteStorage:createEvent(moduleName, functionName)
    self.remotesToClient:insert(moduleName, functionName, remote)

    local function firePlayer(player, ...)
        if _G.DEV then
            self.reporter:assert(
                typeof(player) == 'Instance' and player:IsA('Player'),
                'first argument must be a Player in function call `%s.%s` (got `%s` of type %s)',
                moduleName,
                functionName,
                tostring(player),
                typeof(player)
            )
        end
        if self.isPlayerReady(player) then
            remote:FireClient(player, ...)
        end
    end

    local function fireAllPlayers(...)
        for _, player in ipairs(self.playersService:GetPlayers()) do
            if self.isPlayerReady(player) then
                remote:FireClient(player, ...)
            end
        end
    end

    return firePlayer, fireAllPlayers
end

function ServerRemotes:addFunctionToClient(
    moduleName: string,
    functionName: string
): ((Player, ...any) -> any, (
    ...any
) -> (boolean, { [Player]: { [number]: any, n: number } }))
    local self = self :: ServerRemotes & Private

    self.nameServerMap[moduleName] = false

    local remote = self.remoteStorage:createFunction(moduleName, functionName)
    self.remotesToClient:insert(moduleName, functionName, remote)

    local function firePlayer(player: Player, ...: any): any
        if _G.DEV then
            self.reporter:assert(
                typeof(player) == 'Instance' and player:IsA('Player'),
                'first argument must be a Player in function call `%s.%s` (got `%s` of type %s)',
                moduleName,
                functionName,
                tostring(player),
                typeof(player)
            )
        end
        if self.isPlayerReady(player) then
            return select(2, pcall(remote.InvokeClient, remote, player, ...))
        end
        return
    end

    local function fireAllPlayers(...): (boolean, { [Player]: { [number]: any, n: number } })
        local results = {}
        local totalPlayers = 0
        local totalResults = 0
        local isCollecting = true

        for _, player in ipairs(self.playersService:GetPlayers()) do
            if self.isPlayerReady(player) then
                totalPlayers = totalPlayers + 1
                task.spawn(function(...)
                    local result = table.pack(pcall(remote.InvokeClient, remote, player, ...))
                    local success = result[1]
                    if isCollecting and success then
                        results[player] = table.pack(unpack(result, 2, result.n))
                        totalResults = totalResults + 1
                    end
                end, ...)
            end
        end

        local startTime = os.clock()
        repeat
            task.wait()
        until totalResults == totalPlayers or (os.clock() - startTime) > self.remoteCallMaxDelay
        isCollecting = false

        return totalResults == totalPlayers, results
    end

    return firePlayer, fireAllPlayers
end

function ServerRemotes:addEventToServer<Args...>(
    moduleName: string,
    functionName: string,
    func: (Player, Args...) -> boolean,
    security: RemoteSecurity?
)
    local self = self :: ServerRemotes & Private

    local security: RemoteSecurity = security or 'High'

    self.nameServerMap[moduleName] = true

    local remote = self.remoteStorage:createEvent(moduleName, functionName)
    self.remotesToServer:insert(moduleName, functionName, remote)
    self.remoteSecurity:insert(moduleName, functionName, security)

    if security == 'None' then
        remote.OnServerEvent:Connect(function(player, ...)
            if not func(player, ...) then
                task.spawn(self.onUnapprovedExecution, player, moduleName, functionName)
            end
        end)
    elseif security == 'High' then
        remote.OnServerEvent:Connect(function(player, key, ...)
            if self.keyStorage:verifyKey(player, moduleName, functionName, key) then
                self.keyStorage:setNewKey(player, moduleName, functionName)
                if not func(player, ...) then
                    task.spawn(self.onUnapprovedExecution, player, moduleName, functionName)
                end
            end
        end)
    elseif security == 'Low' then
        remote.OnServerEvent:Connect(function(player, key, ...)
            if self.keyStorage:verifyKey(player, moduleName, functionName, key) then
                if not func(player, ...) then
                    task.spawn(self.onUnapprovedExecution, player, moduleName, functionName)
                end
            end
        end)
    else
        self.reporter:error(
            'Unknown security level `%s`. Valid options are: High, Low or None',
            tostring(security)
        )
    end
end

function ServerRemotes:addFunctionToServer<T..., U...>(
    moduleName: string,
    functionName: string,
    func: (Player, T...) -> (boolean, U...),
    security: RemoteSecurity?
)
    local self = self :: ServerRemotes & Private

    local security: RemoteSecurity = security or 'High'

    self.nameServerMap[moduleName] = true

    local remote = self.remoteStorage:createFunction(moduleName, functionName)
    self.remotesToServer:insert(moduleName, functionName, remote)

    if security == 'None' then
        function remote.OnServerInvoke(player, ...)
            local results = table.pack(func(player, ...))
            if results[1] then
                return unpack(results, 2, results.n)
            else
                task.spawn(self.onUnapprovedExecution, player, moduleName, functionName)
            end
            return
        end
    elseif security == 'High' then
        function remote.OnServerInvoke(player, key, ...)
            if self.keyStorage:verifyKey(player, moduleName, functionName, key) then
                self.keyStorage:setNewKey(player, moduleName, functionName)
                local results = table.pack(func(player, ...))
                if results[1] then
                    return unpack(results, 2, results.n)
                else
                    task.spawn(self.onUnapprovedExecution, player, moduleName, functionName)
                end
            end
            return
        end
    elseif security == 'Low' then
        function remote.OnServerInvoke(player, key, ...)
            if self.keyStorage:verifyKey(player, moduleName, functionName, key) then
                local results = table.pack(func(player, ...))
                if results[1] then
                    return unpack(results, 2, results.n)
                else
                    task.spawn(self.onUnapprovedExecution, player, moduleName, functionName)
                end
            end
            return
        end
    else
        self.reporter:error(
            'Unknown security level `%s`. Valid options are: High, Low or None',
            tostring(security)
        )
    end
end

function ServerRemotes:getRemoteInformation(player: Player): RemoteInformation
    local self = self :: ServerRemotes & Private

    local keys = {}
    local names = {}
    local waitForNames: { [string]: { [string]: true } } = {}

    for moduleName, functions in pairs(self.remotesToServer.content) do
        names[moduleName] = {}
        waitForNames[moduleName] = {}
        keys[moduleName] = {}

        for funcName in pairs(functions) do
            local security = self.remoteSecurity:get(moduleName, funcName)
            if security ~= 'None' then
                keys[moduleName][funcName] = self.keyStorage:createKey(player, moduleName, funcName)
            end

            names[moduleName][funcName] = self.remoteStorage:getRemoteId(moduleName, funcName)

            if security == 'High' then
                waitForNames[moduleName][funcName] = true
            end
        end
    end

    for moduleName, functions in pairs(self.remotesToClient.content) do
        self.reporter:assert(
            names[moduleName] == nil,
            'Server modules and client modules can not have the same name (%s)',
            moduleName
        )

        names[moduleName] = {}

        for funcName in pairs(functions) do
            names[moduleName][funcName] = self.remoteStorage:getRemoteId(moduleName, funcName)
        end
    end

    return {
        Keys = keys,
        Names = names,
        WaitForKeyNames = waitForNames,
        NameServerMap = self.nameServerMap,
    }
end

function ServerRemotes:setOnUnapprovedExecution(callback: (Player, string, string) -> ())
    local self = self :: ServerRemotes & Private

    self.onUnapprovedExecution = callback
end

function ServerRemotes:clearPlayer(player: Player)
    local self = self :: ServerRemotes & Private

    self.keyStorage:clearPlayer(player)
end

return ServerRemotes
