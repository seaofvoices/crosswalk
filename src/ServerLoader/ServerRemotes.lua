local Players = game:GetService('Players')

local ServerLoaderModule = script.Parent
local Common = ServerLoaderModule:FindFirstChild('Common')

local Map2D = require(ServerLoaderModule:FindFirstChild('Map2D'))
local Reporter = require(Common:FindFirstChild('Reporter'))

local ServerRemotes = {}
local ServerRemotesMetatable = { __index = ServerRemotes }

function ServerRemotes:addEventToClient(moduleName, functionName)
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

function ServerRemotes:addFunctionToClient(moduleName, functionName)
    self.nameServerMap[moduleName] = false

    local remote = self.remoteStorage:createFunction(moduleName, functionName)
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
            return select(2, pcall(remote.InvokeClient, remote, player, ...))
        end
    end

    local function fireAllPlayers(...)
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

function ServerRemotes:addEventToServer(moduleName, functionName, func, security)
    security = security or 'High'

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

function ServerRemotes:addFunctionToServer(moduleName, functionName, func, security)
    security = security or 'High'

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
        end
    else
        self.reporter:error(
            'Unknown security level `%s`. Valid options are: High, Low or None',
            tostring(security)
        )
    end
end

function ServerRemotes:getRemoteInformation(player)
    local keys = {}
    local names = {}
    local waitForNames = {}

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

function ServerRemotes:setOnUnapprovedExecution(callback)
    self.onUnapprovedExecution = callback
end

function ServerRemotes:clearPlayer(player)
    self.keyStorage:clearPlayer(player)
end

local function new(options)
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
    }, ServerRemotesMetatable)
end

return {
    new = new,
}
