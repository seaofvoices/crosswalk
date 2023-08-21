local ClientServices = require('./ClientServices')
type Services = ClientServices.Services
local requireModule = require('../Common/requireModule')
type CrosswalkModule = requireModule.CrosswalkModule
type LoadedModuleInfo = requireModule.LoadedModuleInfo
local Reporter = require('../Common/Reporter')
type Reporter = Reporter.Reporter
local loadModules = require('../Common/loadModules')
local validateSharedModule = require('../Common/validateSharedModule')
local defaultCustomModuleFilter = require('../Common/defaultCustomModuleFilter')
local defaultExcludeModuleFilter = require('../Common/defaultExcludeModuleFilter')
local filterArray = require('../Common/filterArray')
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
    _customModuleFilter: (ModuleScript) -> boolean,
    _excludeModuleFilter: (ModuleScript) -> boolean,

    _loadSharedModules: (self: ClientModuleLoader) -> { LoadedModuleInfo },
    _loadClientModules: (self: ClientModuleLoader) -> { LoadedModuleInfo },
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
    customModuleFilter: ((ModuleScript) -> boolean)?,
    excludeModuleFilter: ((ModuleScript) -> boolean)?,
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

    local function removeCustomModuleFilter(moduleInfo: LoadedModuleInfo): boolean
        return not self._customModuleFilter(moduleInfo.moduleScript)
    end

    local setupSharedModules = filterArray(onlySharedModules, removeCustomModuleFilter)

    self._reporter:debug('loading client modules')
    local onlyClientModules = self:_loadClientModules()

    local setupClientModules = filterArray(onlyClientModules, removeCustomModuleFilter)

    self._reporter:info('calling `Init` for shared modules')
    for _, moduleInfo in setupSharedModules do
        if moduleInfo.module.Init then
            self._reporter:info('calling `Init` on `%s`', moduleInfo.name)
            moduleInfo.module.Init()
        end
    end

    self._reporter:info('calling `Init` for client modules')
    for _, moduleInfo in setupClientModules do
        if moduleInfo.module.Init then
            self._reporter:info('calling `Init` on `%s`', moduleInfo.name)
            moduleInfo.module.Init()
        end
    end

    self._reporter:info('calling `Start` for shared modules')
    for _, moduleInfo in onlySharedModules do
        if moduleInfo.module.Start then
            self._reporter:info('calling `Start` on `%s`', moduleInfo.name)
            moduleInfo.module.Start()
        end
    end

    self._reporter:info('calling `Start` for client modules')
    for _, moduleInfo in onlyClientModules do
        if moduleInfo.module.Start then
            self._reporter:info('calling `Start` on `%s`', moduleInfo.name)
            moduleInfo.module.Start()
        end
    end

    self._clientRemotes:fireReadyRemote()

    self._reporter:info('calling `OnPlayerReady` for client modules')
    for _, moduleInfo in onlyClientModules do
        if moduleInfo.module.OnPlayerReady then
            self._reporter:info('calling `OnPlayerReady` on `%s`', moduleInfo.name)
            task.spawn(moduleInfo.module.OnPlayerReady, self._player)
        end
    end

    self._hasLoaded = true
end

function ClientModuleLoader:_loadSharedModules(): { LoadedModuleInfo }
    local self = self :: ClientModuleLoader & Private

    return loadModules(self._sharedScripts, {
        reporter = self._reporter,
        verifyName = function(subModuleName, localModules)
            self:_verifySharedModuleName(subModuleName, localModules)
        end,
        excludeModuleFilter = self._excludeModuleFilter,
        localModulesMap = self._localModules,
        requireModule = self._requireModule,
        useRecursiveMode = self._useRecursiveMode,
        moduleKind = 'shared',
        rootModulesMap = self._shared,
        onRootLoaded = function(moduleInfo)
            if _G.DEV and not self._customModuleFilter(moduleInfo.moduleScript) then
                validateSharedModule(moduleInfo.module, moduleInfo.name, self._reporter)
            end

            self._client[moduleInfo.name] = moduleInfo.module
        end,
    }, self._services, false)
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

function ClientModuleLoader:_loadClientModules(): { LoadedModuleInfo }
    local self = self :: ClientModuleLoader & Private

    local serverModules = self._clientRemotes:getServerModules()

    return loadModules(self._clientScripts, {
        reporter = self._reporter,
        verifyName = function(subModuleName, localModules)
            self:_verifyClientModuleName(subModuleName, localModules)
        end,
        excludeModuleFilter = self._excludeModuleFilter,
        localModulesMap = self._localModules,
        baseModules = self._shared,
        requireModule = self._requireModule,
        useRecursiveMode = self._useRecursiveMode,
        moduleKind = 'client',
        rootModulesMap = self._client,
        onRootLoaded = function(moduleInfo)
            if self._customModuleFilter(moduleInfo.moduleScript) then
                self._reporter:debug('skip client module setup for `%s`', moduleInfo.name)
                return
            end

            local module = moduleInfo.module
            local moduleName = moduleInfo.name

            local api = {}
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
        end,
    }, serverModules, self._services)
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
        _customModuleFilter = options.customModuleFilter or defaultCustomModuleFilter,
        _excludeModuleFilter = options.excludeModuleFilter or defaultExcludeModuleFilter,
        _reporter = options.reporter or Reporter.default(),
        _services = options.services or ClientServices,
        _useRecursiveMode = if options.useRecursiveMode == nil
            then true
            else options.useRecursiveMode,
        _localModules = {},
    }, ClientModuleLoaderMetatable) :: any
end

return ClientModuleLoader
