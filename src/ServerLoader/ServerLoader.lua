local ReplicatedStorage = game:GetService('ReplicatedStorage')

local createKey = require(script.Parent.createKey)
local createKeySender = require(script.Parent.createKeySender)
local KeyStorage = require(script.Parent.KeyStorage)
local ModuleLoader = require(script.Parent.ModuleLoader)
local RemoteStorage = require(script.Parent.RemoteStorage)
local Reporter = require(script.Parent.Reporter)
local ServerRemotes = require(script.Parent.ServerRemotes)
local Services = require(script.Parent.Services)

local DEFAULT_REMOTE_CALL_MAX_DELAY = 2

local ServerLoader = {}
local ServerLoaderMetatable = { __index = ServerLoader }

function ServerLoader:start()
    local playerReadyRemote = self.remoteStorage:createOrphanEvent(createKey() .. '    ')
    table.insert(
        self.connections,
        playerReadyRemote.OnServerEvent:Connect(function(player)
            while not self.moduleLoader:hasLoaded() do
                task.wait()
            end
            if player.Parent then
                self.isPlayerReadyMap[player] = true
                self.moduleLoader:onPlayerReady(player)
            end
        end)
    )

    local dataSenderRemote = self.remoteStorage:createOrphanFunction(createKey() .. '  ')

    function dataSenderRemote.OnServerInvoke(player)
        if self.remoteDataSent[player] == nil then
            self.remoteDataSent[player] = true
            return self.serverRemotes:getRemoteInformation(player)
        else
            self.onSecondPlayerRequest(player)
        end
    end

    local playerRemoving = self.services.Players.PlayerRemoving
    table.insert(
        self.connections,
        playerRemoving:Connect(function(player)
            self.isPlayerReadyMap[player] = nil
            self.remoteDataSent[player] = nil
            self.moduleLoader:onPlayerRemoving(player)
        end)
    )

    self.remoteParent.Parent = ReplicatedStorage

    self.serverRemotes:setOnUnapprovedExecution(function(player, module, functionName)
        local ran = self.moduleLoader:onUnapprovedExecution(player, module, functionName)

        if not ran then
            self.onUnapprovedExecution(player, {
                moduleName = module,
                functionName = functionName,
            })
        end
    end)
    self.moduleLoader:loadModules()
end

function ServerLoader:stop()
    for _, connection in ipairs(self.connections) do
        connection:Disconnect()
    end
    self.connections = {}
    self.remoteParent.Parent = nil
end

local function new(configuration)
    local remoteParent = Instance.new('Folder')
    remoteParent.Name = 'Remotes'

    local reporter = configuration.reporter or Reporter.default()
    local remoteStorage = RemoteStorage.new(remoteParent)

    local isPlayerReadyMap = {}

    local keyStorage = KeyStorage.new({
        reporter = reporter,
        sendKey = createKeySender(remoteStorage),
        onKeyError = configuration.onKeyError or function() end,
        onKeyMissing = configuration.onKeyMissing or function() end,
    })

    local serverRemotes = ServerRemotes.new({
        isPlayerReady = function(player)
            return isPlayerReadyMap[player] == true
        end,
        remoteStorage = remoteStorage,
        keyStorage = keyStorage,
        remoteCallMaxDelay = configuration.remoteCallMaxDelay or DEFAULT_REMOTE_CALL_MAX_DELAY,
    })

    local moduleLoader = configuration.moduleLoader
        or ModuleLoader.new({
            shared = configuration.sharedModules,
            server = configuration.serverModules,
            client = configuration.clientModules,
            serverRemotes = serverRemotes,
            reporter = reporter,
        })

    return setmetatable({
        remoteDataSent = {},
        connections = {},
        isPlayerReadyMap = isPlayerReadyMap,
        remoteParent = remoteParent,
        remoteStorage = remoteStorage,
        serverRemotes = serverRemotes,
        moduleLoader = moduleLoader,
        services = configuration.services or Services,
        onSecondPlayerRequest = configuration.onSecondPlayerRequest or function(_player) end,
        onUnapprovedExecution = configuration.onUnapprovedExecution
            or function(_player, _moduleName, _info) end,
    }, ServerLoaderMetatable)
end

return {
    new = new,
}
