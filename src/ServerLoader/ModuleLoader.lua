local getSecurity = require('./getSecurity')
local Services = require('./Services')
local Reporter = require('../Common/Reporter')
type Reporter = Reporter.Reporter
local requireModule = require('../Common/requireModule')
type CrosswalkModule = requireModule.CrosswalkModule
type LoadedModuleInfo = requireModule.LoadedModuleInfo
local loadModules = require('../Common/loadModules')
local validateSharedModule = require('../Common/validateSharedModule')
local extractFunctionName = require('../Common/extractFunctionName')
local defaultCustomModuleFilter = require('../Common/defaultCustomModuleFilter')
local defaultExcludeModuleFilter = require('../Common/defaultExcludeModuleFilter')
local ServerRemotes = require('./ServerRemotes')
type ServerRemotes = ServerRemotes.ServerRemotes

local EVENT_PATTERN = '_event$'
local FUNCTION_PATTERN = '_func$'

export type ModuleLoader = {
    loadModules: (self: ModuleLoader) -> (),
    onPlayerReady: (self: ModuleLoader, player: Player) -> (),
    onPlayerRemoving: (self: ModuleLoader, player: Player) -> (),
    onUnapprovedExecution: (
        self: ModuleLoader,
        player: Player,
        moduleName: string,
        functionName: string
    ) -> boolean,
    hasLoaded: (self: ModuleLoader) -> boolean,
}

type Private = {
    _hasLoaded: boolean,
    _serverScripts: { ModuleScript },
    _clientScripts: { ModuleScript },
    _sharedScripts: { ModuleScript },
    _external: { [string]: any },
    _ranOnPlayerReady: { [Player]: true },
    _shared: { [string]: any },
    _server: { [string]: any },
    _onlyServer: { LoadedModuleInfo },
    _client: { [string]: any },
    _serverRemotes: ServerRemotes,
    _reporter: Reporter.Reporter,
    _requireModule: <T...>(moduleScript: ModuleScript, T...) -> CrosswalkModule,
    _services: Services.Services,
    _customModuleFilter: (ModuleScript) -> boolean,
    _excludeModuleFilter: (ModuleScript) -> boolean,

    _useRecursiveMode: boolean,
    _localModules: { [ModuleScript]: { [string]: any } },

    _verifyServerModuleName: (
        self: ModuleLoader,
        moduleName: string,
        localModules: { [string]: any }
    ) -> (),
    _verifySharedModuleName: (
        self: ModuleLoader,
        moduleName: string,
        localModules: { [string]: any }
    ) -> (),

    _loadSharedModules: (self: ModuleLoader) -> { LoadedModuleInfo },
    _loadServerModules: (self: ModuleLoader) -> { LoadedModuleInfo },
    _setupClientRemotes: (self: ModuleLoader) -> (),
    _validateReturnedValues: (
        self: ModuleLoader,
        values: { any },
        context: { moduleName: string, functionName: string, moduleFunction: () -> () }
    ) -> (),
}

export type NewModuleLoaderOptions = {
    server: { ModuleScript },
    client: { ModuleScript },
    shared: { ModuleScript },
    external: { [string]: any }?,
    serverRemotes: ServerRemotes,
    reporter: Reporter?,
    requireModule: <T...>(moduleScript: ModuleScript, T...) -> ()?,
    services: Services.Services?,
    useRecursiveMode: boolean?,
    customModuleFilter: ((ModuleScript) -> boolean)?,
    excludeModuleFilter: ((ModuleScript) -> boolean)?,
}

type ModuleLoaderStatic = ModuleLoader & Private & {
    new: (NewModuleLoaderOptions) -> ModuleLoader,
}

local ModuleLoader: ModuleLoaderStatic = {} :: any
local ModuleLoaderMetatable = {
    __index = ModuleLoader,
}

function ModuleLoader:loadModules()
    local self = self :: ModuleLoader & Private

    self._reporter:assert(
        not self._hasLoaded,
        'modules were already loaded once and cannot be loaded twice!'
    )

    for moduleName, externalModule in self._external do
        self._reporter:debug('adding external module `%s`', moduleName)
        self._shared[moduleName] = externalModule
        self._server[moduleName] = externalModule
    end

    self._reporter:debug('loading shared modules')
    local onlyShared = self:_loadSharedModules()

    local setupSharedModules = {}
    for _, moduleInfo in onlyShared do
        if not self._customModuleFilter(moduleInfo.moduleScript) then
            table.insert(setupSharedModules, moduleInfo)
        end
    end

    self._reporter:debug('loading server modules')
    local onlyServer = self:_loadServerModules()

    local setupServerModules = {}
    for _, moduleInfo in onlyServer do
        if not self._customModuleFilter(moduleInfo.moduleScript) then
            table.insert(setupServerModules, moduleInfo)
        end
    end
    self._onlyServer = setupServerModules

    self._reporter:info('calling `Init` for shared modules')
    for _, moduleInfo in setupSharedModules do
        if moduleInfo.module.Init then
            self._reporter:debug('calling `Init` on `%s`', moduleInfo.name)
            moduleInfo.module.Init()
        end
    end

    self._reporter:info('calling `Init` for server modules')
    for _, moduleInfo in setupServerModules do
        if moduleInfo.module.Init then
            self._reporter:debug('calling `Init` on `%s`', moduleInfo.name)
            moduleInfo.module.Init()
        end
    end

    self._reporter:debug('setup remotes for client modules')
    self:_setupClientRemotes()

    self._reporter:info('calling `Start` for shared modules')
    for _, moduleInfo in setupSharedModules do
        if moduleInfo.module.Start then
            self._reporter:debug('calling `Start` on `%s`', moduleInfo.name)
            moduleInfo.module.Start()
        end
    end

    self._reporter:info('calling `Start` for server modules')
    for _, moduleInfo in setupServerModules do
        if moduleInfo.module.Start then
            self._reporter:debug('calling `Start` on `%s`', moduleInfo.name)
            moduleInfo.module.Start()
        end
    end

    self._hasLoaded = true
end

function ModuleLoader:_loadSharedModules(): { LoadedModuleInfo }
    local self = self :: ModuleLoader & Private

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

            self._server[moduleInfo.name] = moduleInfo.module
        end,
    }, self._services, true)
end

function ModuleLoader:_verifySharedModuleName(moduleName: string, localModules: { [string]: any })
    local self = self :: ModuleLoader & Private

    self._reporter:assert(
        self._external[moduleName] == nil,
        'shared module named %q was already provided as an external server module. Rename '
            .. 'the shared module or the external module',
        moduleName
    )
    self._reporter:assert(
        self._shared[moduleName] == nil and localModules[moduleName] == nil,
        'shared module named %q was already registered as a shared module',
        moduleName
    )
end

function ModuleLoader:_verifyServerModuleName(moduleName: string, localModules: { [string]: any })
    local self = self :: ModuleLoader & Private

    self._reporter:assert(
        self._external[moduleName] == nil,
        'server module named %q was already provided as an external server module. Rename '
            .. 'the server module or the external module',
        moduleName
    )
    self._reporter:assert(
        self._shared[moduleName] == nil,
        'server module named %q was already registered as a shared module',
        moduleName
    )
    self._reporter:assert(
        localModules[moduleName] == nil,
        'server module named %q was already registered as a server module',
        moduleName
    )
end

function ModuleLoader:_loadServerModules(): { LoadedModuleInfo }
    local self = self :: ModuleLoader & Private

    return loadModules(self._serverScripts, {
        reporter = self._reporter,
        verifyName = function(subModuleName, localModules)
            self:_verifyServerModuleName(subModuleName, localModules)
        end,
        excludeModuleFilter = self._excludeModuleFilter,
        localModulesMap = self._localModules,
        requireModule = self._requireModule,
        useRecursiveMode = self._useRecursiveMode,
        moduleKind = 'server',
        rootModulesMap = self._server,
        baseModules = self._shared,
        onRootLoaded = function(moduleInfo)
            if self._customModuleFilter(moduleInfo.moduleScript) then
                self._reporter:debug('skip server module setup for `%s`', moduleInfo.name)
                return
            end

            local moduleName = moduleInfo.name
            local module = moduleInfo.module

            local api = {}

            for functionName, func in pairs(module) do
                if type(func) == 'function' then
                    local name = nil
                    local serverToServerFunction = nil

                    if functionName:match(EVENT_PATTERN) then
                        name = extractFunctionName(functionName)
                        self._serverRemotes:addEventToServer(
                            moduleName,
                            name,
                            func :: any,
                            getSecurity(functionName)
                        )
                        serverToServerFunction = function(...)
                            if _G.DEV then
                                local values = table.pack(func(...))
                                self:_validateReturnedValues(values, {
                                    moduleName = moduleName,
                                    functionName = functionName,
                                    moduleFunction = func,
                                })

                                if values.n > 1 then
                                    self._reporter:warn(
                                        'function `%s.%s` is declared as an exposed remote '
                                            .. 'event, but it is returning more than the '
                                            .. 'required validation boolean.\n\nTo make this '
                                            .. 'function return values to clients, replace '
                                            .. 'the `_event` suffix with `_func`. If the '
                                            .. 'function does not need to return values, '
                                            .. 'remove them as they are ignored by crosswalk',
                                        moduleName,
                                        functionName
                                    )
                                end
                            else
                                func(...)
                            end
                        end
                    elseif functionName:match(FUNCTION_PATTERN) then
                        name = extractFunctionName(functionName)
                        self._serverRemotes:addFunctionToServer(
                            moduleName,
                            name,
                            func :: any,
                            getSecurity(functionName)
                        )
                        serverToServerFunction = function(...)
                            if _G.DEV then
                                local values = table.pack(func(...))
                                self:_validateReturnedValues(values, {
                                    moduleName = moduleName,
                                    functionName = functionName,
                                    moduleFunction = func,
                                })

                                return unpack(values, 2, values.n)
                            else
                                return select(2, (func :: any)(...))
                            end
                        end
                    end

                    if name then
                        self._reporter:assert(
                            api[name] == nil,
                            'server module named %q has defined two functions that resolves to the '
                                .. 'same name `%s`. Rename one of them or remove an unused one',
                            moduleName,
                            name
                        )
                        self._reporter:assert(
                            module[name] == nil,
                            'server module named %q already has a %s named `%s` that collides '
                                .. 'with the generated function from `%s`',
                            moduleName,
                            typeof(api[name]) == 'function' and 'function' or 'value',
                            name,
                            functionName
                        )
                        api[name] = serverToServerFunction
                    end
                end
            end

            for name, newFunction in api do
                module[name] = newFunction
            end
        end,
    }, self._client, self._services)
end

function ModuleLoader:_setupClientRemotes()
    local self = self :: ModuleLoader & Private

    for _, moduleScript in self._clientScripts do
        if self._excludeModuleFilter(moduleScript) then
            self._reporter:debug('exclude module `%s`', moduleScript.Name)
            continue
        end
        local moduleName = moduleScript.Name

        self._reporter:assert(
            self._shared[moduleName] == nil,
            'client module named %q was already registered as a shared module',
            moduleName
        )
        self._reporter:assert(
            self._server[moduleName] == nil,
            'client module named %q was already registered as a server module',
            moduleName
        )
        self._reporter:assert(
            self._client[moduleName] == nil,
            'client module named %q was already registered as a client module',
            moduleName
        )

        if self._customModuleFilter(moduleScript) then
            -- if the client module is a custom module, then there will be no
            -- remote events to setup
            self._reporter:debug('skip client module setup for `%s`', moduleName)
            continue
        end

        local module = self._requireModule(moduleScript, {}, {}, Services)

        local api = {}

        for functionName, func in pairs(module) do
            if type(func) == 'function' then
                local name = nil
                local callClient = nil
                local callAllClients = nil

                if functionName:match('_event$') then
                    name = functionName:match('(.+)_event$')
                    callClient, callAllClients =
                        self._serverRemotes:addEventToClient(moduleName, name)
                elseif functionName:match('_func$') then
                    name = functionName:match('(.+)_func$')
                    callClient, callAllClients =
                        self._serverRemotes:addFunctionToClient(moduleName, name)
                end

                if name then
                    self._reporter:assert(
                        api[name] == nil,
                        'client module named %q has defined two functions that resolves to the '
                            .. 'same name `%s`: `%s` and `%s`. Rename one of them or remove an '
                            .. 'unused one',
                        moduleName,
                        name,
                        name .. '_event',
                        name .. '_func'
                    )
                    local nameForAll = name .. 'All'
                    self._reporter:assert(
                        module[name] == nil,
                        'client module named %q already has a %s named `%s` that collides '
                            .. 'with the generated function from `%s`',
                        moduleName,
                        typeof(api[name]) == 'function' and 'function' or 'value',
                        name,
                        functionName
                    )
                    self._reporter:assert(
                        module[nameForAll] == nil,
                        'client module named %q already has a %s named `%s` that collides '
                            .. 'with the generated function from `%s`',
                        moduleName,
                        typeof(api[name]) == 'function' and 'function' or 'value',
                        nameForAll,
                        functionName
                    )

                    api[name] = callClient
                    api[nameForAll] = callAllClients
                end
            end
        end

        self._client[moduleName] = api
    end
end

function ModuleLoader:onPlayerReady(player: Player)
    local self = self :: ModuleLoader & Private

    self._reporter:assert(
        self._ranOnPlayerReady[player] == nil,
        'onPlayerReady was already called for player %q',
        player.Name
    )
    self._ranOnPlayerReady[player] = true

    self._reporter:info('calling `OnPlayerReady` for player `%s` (%d)', player.Name, player.UserId)
    for _, moduleInfo in self._onlyServer do
        if moduleInfo.module.OnPlayerReady then
            self._reporter:debug(
                'calling `OnPlayerReady` on `%s` for `%s` (%d)',
                moduleInfo.name,
                player.Name,
                player.UserId
            )
            task.spawn(moduleInfo.module.OnPlayerReady, player)
        end
    end
end

function ModuleLoader:onPlayerRemoving(player: Player)
    local self = self :: ModuleLoader & Private

    self._serverRemotes:clearPlayer(player)
    self._ranOnPlayerReady[player] = nil

    self._reporter:info(
        'calling `OnPlayerLeaving` for player `%s` (%d)',
        player.Name,
        player.UserId
    )
    for _, moduleInfo in self._onlyServer do
        if moduleInfo.module.OnPlayerLeaving then
            self._reporter:debug(
                'calling `OnPlayerLeaving` on `%s` for `%s` (%d)',
                moduleInfo.name,
                player.Name,
                player.UserId
            )
            task.spawn(moduleInfo.module.OnPlayerLeaving, player)
        end
    end
end

function ModuleLoader:onUnapprovedExecution(
    player: Player,
    moduleName: string,
    functionName: string
): boolean
    local self = self :: ModuleLoader & Private

    local module = self._server[moduleName]
    self._reporter:assert(
        module,
        'unapproved execution from player %q: module %q not found (looking for %s)',
        player.Name,
        moduleName,
        functionName
    )

    if module.OnUnapprovedExecution == nil then
        return false
    end

    task.spawn(module.OnUnapprovedExecution, player, {
        functionName = functionName,
    })

    return true
end

function ModuleLoader:hasLoaded(): boolean
    local self = self :: ModuleLoader & Private

    return self._hasLoaded
end

function ModuleLoader:_validateReturnedValues(
    values: { any },
    context: {
        moduleName: string,
        functionName: string,
        moduleFunction: () -> (),
    }
)
    local self = self :: ModuleLoader & Private

    local validated = values[1]
    if typeof(validated) ~= 'boolean' then
        self._reporter:warn(
            'function `%s.%s` should return a boolean to indicate '
                .. 'whether the call was approved or not, but got '
                .. '`%s` (of type `%s`).\n\n'
                .. 'Learn more about server modules function '
                .. 'validation at: %s',
            context.moduleName,
            context.functionName,
            tostring(validated),
            typeof(validated),
            'https://crosswalk.seaofvoices.ca/Guide/ServerModules/#validation'
        )
    elseif not validated then
        local source, line, callerName = debug.info(3, 'sln')
        if callerName == '' or callerName == nil then
            callerName = '<anonymous function>'
        end
        self._reporter:warn(
            'function `%s.%s` is declared as an exposed remote, '
                .. 'but the validation failed when calling '
                .. 'it from `%s` at line %d in server module `%s`',
            context.moduleName,
            context.functionName,
            callerName,
            line,
            source
        )
    end
end

function ModuleLoader.new(options: NewModuleLoaderOptions): ModuleLoader
    return setmetatable({
        _hasLoaded = false,
        _shared = {},
        _server = {},
        _onlyServer = {},
        _client = {},
        _external = options.external or {},
        _ranOnPlayerReady = {},
        _sharedScripts = options.shared,
        _serverScripts = options.server,
        _clientScripts = options.client,
        _serverRemotes = options.serverRemotes,
        _customModuleFilter = options.customModuleFilter or defaultCustomModuleFilter,
        _excludeModuleFilter = options.excludeModuleFilter or defaultExcludeModuleFilter,
        _reporter = options.reporter or Reporter.default(),
        _services = options.services or Services,
        _requireModule = options.requireModule or requireModule,
        _useRecursiveMode = if options.useRecursiveMode == nil
            then true
            else options.useRecursiveMode,
        _localModules = {},
    }, ModuleLoaderMetatable) :: any
end

return ModuleLoader
