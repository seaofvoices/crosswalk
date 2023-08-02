local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local ClientLoaderModule = script.Parent
local Common = ClientLoaderModule:WaitForChild('Common')

local ClientServices = require(ClientLoaderModule:WaitForChild('ClientServices'))
local ClientModuleLoader = require(ClientLoaderModule:WaitForChild('ClientModuleLoader'))
local ClientRemotes = require(ClientLoaderModule:WaitForChild('ClientRemotes'))
local Reporter = require(Common:WaitForChild('Reporter'))

local ClientLoader = {}
local ClientLoaderMetatable = { __index = ClientLoader }

function ClientLoader:start()
    self.clientModuleLoader:loadModules()
end

function ClientLoader:stop()
    self.clientRemotes:disconnect()
end

local function new(configuration)
    local reporter = configuration.reporter
    if reporter == nil then
        if configuration.logLevel == nil then
            reporter = Reporter.default()
        else
            reporter = Reporter.fromLogLevel(configuration.logLevel)
        end
    end
    local player = configuration.player or Players.LocalPlayer

    local clientRemotes = ClientRemotes.new({
        remotesParent = ReplicatedStorage,
        reporter = reporter,
    })

    local clientModuleLoader = configuration.clientModuleLoader
        or ClientModuleLoader.new({
            shared = configuration.sharedModules,
            client = configuration.clientModules,
            external = configuration.externalModules,
            player = player,
            reporter = reporter,
            services = configuration.services or ClientServices,
            clientRemotes = clientRemotes,
        })

    return setmetatable({
        player = player,
        clientModuleLoader = clientModuleLoader,
        reporter = reporter,
    }, ClientLoaderMetatable)
end

return {
    new = new,
}
