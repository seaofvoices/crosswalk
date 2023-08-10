local ClientServices = require('./ClientServices')
type Services = ClientServices.Services
local requireModule = require('../Common/requireModule')
type CrosswalkModule = requireModule.CrosswalkModule
local Reporter = require('../Common/Reporter')
type Reporter = Reporter.Reporter
local loadNestedModules = require('../Common/loadNestedModules')
local validateSharedModule = require('../Common/validateSharedModule')
local ClientRemotes = require('./ClientRemotes')
type ClientRemotes = ClientRemotes.ClientRemotes

local EVENT_PATTERN = '_event$'
local FUNCTION_PATTERN = '_func$'

export type ClientModuleLoader = {
    loadModules: (self: ClientModuleLoader) -> (),
}

type Private = {
    _hasLoaded: boolean,
    _player: Player,
    _clientScripts: { ModuleScript },
    _sharedScripts: { ModuleScript },
    _external: { [string]: any },
    _shared: { [string]: any },
    _client: { [string]: any },
    _clientRemotes: ClientRemotes,
    _reporter: Reporter,
    _requireModule: <T...>(moduleScript: ModuleScript, T...) -> CrosswalkModule,
    _services: Services,

    _loadSharedModules: (self: ClientModuleLoader) -> { CrosswalkModule },
    _loadClientModules: (self: ClientModuleLoader) -> { CrosswalkModule },
    _verifyClientModuleName: (
        self: ClientModuleLoader,
        moduleName: string,
        localModules: { [string]: any }
    ) -> (),
    _verifySharedModuleName: (
        self: ClientModuleLoader,
        moduleName: string,
        localModules: { [string]: any }
    ) -> (),

    _useRecursiveMode: boolean,
    _localModules: { [ModuleScript]: { [string]: any } },
}

type NewClientModuleLoaderOptions = {
    player: Player,
    client: { ModuleScript },
    shared: { ModuleScript },
    external: { [string]: any }?,
    clientRemotes: ClientRemotes,
    reporter: Reporter?,
    requireModule: <T...>(moduleScript: ModuleScript, T...) -> ()?,
    services: Services?,
    useRecursiveMode: boolean?,
}

type ClientModuleLoaderStatic = ClientModuleLoader & Private & {
    new: (options: NewClientModuleLoaderOptions) -> ClientModuleLoader,
}

local ClientModuleLoader: ClientModuleLoaderStatic = {} :: any
local ClientModuleLoaderMetatable = {
    __index = ClientModuleLoader,
}

function ClientModuleLoader:loadModules()
    local self = self :: ClientModuleLoader & Private

    self._reporter:assert(
        not self._hasLoaded,
        'modules were already loaded once and cannot be loaded twice!'
    )

    self._clientRemotes:listen()

    for moduleName, externalModule in self._external do
        self._reporter:debug('adding external module `%s`', moduleName)
        self._shared[moduleName] = externalModule
        self._client[moduleName] = externalModule
    end

    self._reporter:debug('loading shared modules')
    local onlySharedModules = self:_loadSharedModules()

    self._reporter:debug('loading client modules')
    local onlyClientModules = self:_loadClientModules()

    self._reporter:debug('calling `Init` for shared modules')
    for _, module in onlySharedModules do
        if module.Init then
            module.Init()
        end
    end

    self._reporter:debug('calling `Init` for client modules')
    for _, module in onlyClientModules do
        if module.Init then
            module.Init()
        end
    end

    self._reporter:debug('calling `Start` for shared modules')
    for _, module in onlySharedModules do
        if module.Start then
            module.Start()
        end
    end

    self._reporter:debug('calling `Start` for client modules')
    for _, module in onlyClientModules do
        if module.Start then
            module.Start()
        end
    end

    self._clientRemotes:fireReadyRemote()

    self._reporter:debug('calling `OnPlayerReady` for client modules')
    for _, module in onlyClientModules do
        if module.OnPlayerReady then
            task.spawn(module.OnPlayerReady, self._player)
        end
    end

    self._hasLoaded = true
end

function ClientModuleLoader:_loadSharedModules(): { CrosswalkModule }
    local self = self :: ClientModuleLoader & Private

    local sharedModules = {}
    for _, moduleScript in self._sharedScripts do
        local moduleName = moduleScript.Name
        self._reporter:debug('loading shared module `%s`', moduleName)

        self:_verifySharedModuleName(moduleName, self._shared)

        local localSharedModules = nil
        if self._useRecursiveMode then
            localSharedModules = {}
            self._localModules[moduleScript] = localSharedModules
        else
            localSharedModules = self._shared
        end

        local module = self._requireModule(moduleScript, localSharedModules, self._services, false)

        if _G.DEV then
            validateSharedModule(module, moduleName, self._reporter)
        end

        self._shared[moduleName] = module
        self._client[moduleName] = module

        table.insert(sharedModules, module)
    end

    if self._useRecursiveMode then
        for _, moduleScript in self._sharedScripts do
            local localSharedModules = self._localModules[moduleScript]

            for name, content in self._shared do
                localSharedModules[name] = content
            end

            local nestedModules = loadNestedModules(
                moduleScript,
                self._reporter,
                self._requireModule,
                self._localModules,
                function(subModuleName, localModules)
                    self:_verifySharedModuleName(subModuleName, localModules)
                end,
                self._services,
                false
            )
            table.move(nestedModules, 1, #nestedModules, #sharedModules + 1, sharedModules)
        end
    end

    return sharedModules
end

function ClientModuleLoader:_verifySharedModuleName(
    moduleName: string,
    localModules: { [string]: any }
)
    local self = self :: ClientModuleLoader & Private

    self._reporter:assert(
        self._external[moduleName] == nil,
        'shared module named %q was already provided as an external client module. Rename '
            .. 'the shared module or the external module',
        moduleName
    )
    self._reporter:assert(
        localModules[moduleName] == nil,
        'shared module named %q was already registered as a shared module',
        moduleName
    )
end

function ClientModuleLoader:_loadClientModules(): { CrosswalkModule }
    local self = self :: ClientModuleLoader & Private

    local clientModules = {}
    local serverModules = self._clientRemotes:getServerModules()

    for _, moduleScript in self._clientScripts do
        local moduleName = moduleScript.Name
        self._reporter:debug('loading client module `%s`', moduleName)

        self:_verifyClientModuleName(moduleName, self._client)

        local localClientModules = nil
        if self._useRecursiveMode then
            localClientModules = {}
            self._localModules[moduleScript] = localClientModules
        else
            localClientModules = self._client
        end

        local api = {}
        local module =
            self._requireModule(moduleScript, localClientModules, serverModules, self._services)

        for functionName, callback in pairs(module) do
            if type(callback) == 'function' then
                local name = nil
                if functionName:match(EVENT_PATTERN) then
                    name = functionName:match('(.+)_event$')
                elseif functionName:match(FUNCTION_PATTERN) then
                    name = functionName:match('(.+)_func$')
                end

                if name then
                    -- name collisions validation is done in the server ModuleLoader
                    api[name] = callback
                    self._clientRemotes:connectRemote(moduleName, name, callback)
                end
            end
        end

        for name, newFunction in api do
            module[name] = newFunction
        end

        self._client[moduleName] = module
        table.insert(clientModules, module)
    end

    if self._useRecursiveMode then
        for _, moduleScript in self._clientScripts do
            local localClientModules = self._localModules[moduleScript]

            for name, content in self._client do
                localClientModules[name] = content
            end

            local nestedModules = loadNestedModules(
                moduleScript,
                self._reporter,
                self._requireModule,
                self._localModules,
                function(subModuleName, localModules)
                    self:_verifyClientModuleName(subModuleName, localModules)
                end,
                serverModules,
                self._services
            )
            table.move(nestedModules, 1, #nestedModules, #clientModules + 1, clientModules)
        end
    end

    return clientModules
end

function ClientModuleLoader:_verifyClientModuleName(
    moduleName: string,
    localModules: { [string]: any }
)
    local self = self :: ClientModuleLoader & Private

    self._reporter:assert(
        self._external[moduleName] == nil,
        'client module named %q was already provided as an external client module. Rename '
            .. 'the client module or the external module',
        moduleName
    )
    self._reporter:assert(
        self._shared[moduleName] == nil,
        'client module named %q was already registered as a shared module',
        moduleName
    )
    self._reporter:assert(
        localModules[moduleName] == nil,
        'client module named %q was already registered as a client module',
        moduleName
    )
end

function ClientModuleLoader.new(options: NewClientModuleLoaderOptions): ClientModuleLoader
    return setmetatable({
        _hasLoaded = false,
        _shared = {},
        _client = {},
        _external = options.external or {},
        _sharedScripts = options.shared,
        _clientScripts = options.client,
        _player = options.player,
        _clientRemotes = options.clientRemotes,
        _requireModule = options.requireModule or requireModule,
        _reporter = options.reporter or Reporter.default(),
        _services = options.services or ClientServices,
        _useRecursiveMode = if options.useRecursiveMode == nil
            then true
            else options.useRecursiveMode,
        _localModules = {},
    }, ClientModuleLoaderMetatable) :: any
end

return ClientModuleLoader
