local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local ClientServices = require('./ClientServices')
type Services = ClientServices.Services
local ClientModuleLoader = require('./ClientModuleLoader')
type ClientModuleLoader = ClientModuleLoader.ClientModuleLoader
local ClientRemotes = require('./ClientRemotes')
type ClientRemotes = ClientRemotes.ClientRemotes
local Common = require('@pkg/crosswalk-common')
local filterArray = Common.filterArray
local Reporter = Common.Reporter
type Reporter = Common.Reporter
type LogLevel = Common.LogLevel

export type ClientLoader = {
    start: (self: ClientLoader) -> (),
    stop: (self: ClientLoader) -> (),
}

type Private = {
    clientModuleLoader: ClientModuleLoader,
    clientRemotes: ClientRemotes,
}

type ClientLoaderConfiguration = {
    sharedModules: { Instance },
    clientModules: { Instance },
    externalModules: { [string]: any }?,
    clientModuleLoader: ClientModuleLoader?,
    logLevel: LogLevel?,
    customModuleFilter: ((ModuleScript) -> boolean)?,
    excludeModuleFilter: ((ModuleScript) -> boolean)?,
    reporter: Reporter?,
    player: Player?,
    services: Services?,
    useRecursiveMode: boolean?,
}
type ClientLoaderStatic = ClientLoader & Private & {
    new: (configuration: ClientLoaderConfiguration) -> ClientLoader,
}

local function filterModuleScripts(instance: Instance): boolean
    return instance:IsA('ModuleScript')
end

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
            shared = filterArray(configuration.sharedModules, filterModuleScripts) :: any,
            client = filterArray(configuration.clientModules, filterModuleScripts) :: any,
            external = configuration.externalModules,
            player = player,
            reporter = reporter,
            services = configuration.services or ClientServices,
            clientRemotes = clientRemotes,
            customModuleFilter = configuration.customModuleFilter,
            excludeModuleFilter = configuration.excludeModuleFilter,
            useRecursiveMode = configuration.useRecursiveMode,
        })

    return setmetatable({
        player = player,
        clientModuleLoader = clientModuleLoader,
        reporter = reporter,
    }, ClientLoaderMetatable) :: any
end

return ClientLoader
