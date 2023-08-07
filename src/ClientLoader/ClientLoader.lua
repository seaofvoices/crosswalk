local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local ClientServices = require('./ClientServices')
type Services = ClientServices.Services
local ClientModuleLoader = require('./ClientModuleLoader')
type ClientModuleLoader = ClientModuleLoader.ClientModuleLoader
local ClientRemotes = require('./ClientRemotes')
type ClientRemotes = ClientRemotes.ClientRemotes
local Reporter = require('../Common/Reporter')
type Reporter = Reporter.Reporter
type LogLevel = Reporter.LogLevel

export type ClientLoader = {
    start: (self: ClientLoader) -> (),
    stop: (self: ClientLoader) -> (),
}

type Private = {
    clientModuleLoader: ClientModuleLoader,
    clientRemotes: ClientRemotes,
}

type ClientLoaderConfiguration = {
    sharedModules: { ModuleScript },
    clientModules: { ModuleScript },
    externalModules: { [string]: any }?,
    clientModuleLoader: ClientModuleLoader?,
    logLevel: LogLevel?,
    reporter: Reporter?,
    player: Player?,
    services: Services?,
}
type ClientLoaderStatic = ClientLoader & Private & {
    new: (configuration: ClientLoaderConfiguration) -> ClientLoader,
}

local ClientLoader: ClientLoaderStatic = {} :: any
local ClientLoaderMetatable = {
    __index = ClientLoader,
}

function ClientLoader:start()
    local self = self :: ClientLoader & Private
    self.clientModuleLoader:loadModules()
end

function ClientLoader:stop()
    local self = self :: ClientLoader & Private
    self.clientRemotes:disconnect()
end

function ClientLoader.new(configuration: ClientLoaderConfiguration): ClientLoader
    local reporter = if configuration.reporter == nil
        then if configuration.logLevel == nil
            then Reporter.default()
            else Reporter.fromLogLevel(configuration.logLevel)
        else configuration.reporter
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
    }, ClientLoaderMetatable) :: any
end

return ClientLoader
