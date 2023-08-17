local getSecurity = require('./getSecurity')
local Services = require('./Services')
local Reporter = require('../Common/Reporter')
type Reporter = Reporter.Reporter
local requireModule = require('../Common/requireModule')
type CrosswalkModule = requireModule.CrosswalkModule
local loadNestedModules = require('../Common/loadNestedModules')
local validateSharedModule = require('../Common/validateSharedModule')
local extractFunctionName = require('../Common/extractFunctionName')
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
    _onlyShared: { CrosswalkModule },
    _server: { [string]: any },
    _onlyServer: { CrosswalkModule },
    _client: { [string]: any },
    _serverRemotes: ServerRemotes,
    _reporter: Reporter.Reporter,
    _requireModule: <T...>(moduleScript: ModuleScript, T...) -> CrosswalkModule,
    _services: Services.Services,

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

    _loadSharedModules: (self: ModuleLoader) -> { CrosswalkModule },
    _loadServerModules: (self: ModuleLoader) -> { CrosswalkModule },
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
    self._onlyShared = self:_loadSharedModules()

    self._reporter:debug('loading server modules')
    self._onlyServer = self:_loadServerModules()

    self._reporter:debug('calling `Init` for shared modules')
    for _, module in self._onlyShared do
        if module.Init then
            module.Init()
        end
    end

    self._reporter:debug('calling `Init` for server modules')
    for _, module in self._onlyServer do
        if module.Init then
            module.Init()
        end
    end

    self._reporter:debug('setup remotes for client modules')
    self:_setupClientRemotes()

    self._reporter:debug('calling `Start` for shared modules')
    for _, module in self._onlyShared do
        if module.Start then
            module.Start()
        end
    end

    self._reporter:debug('calling `Start` for server modules')
    for _, module in self._onlyServer do
        if module.Start then
            module.Start()
        end
    end

    self._hasLoaded = true
end

function ModuleLoader:_loadSharedModules(): { CrosswalkModule }
    local self = self :: ModuleLoader & Private

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

        local module = self._requireModule(moduleScript, localSharedModules, self._services, true)

        if _G.DEV then
            validateSharedModule(module, moduleName, self._reporter)
        end

        self._shared[moduleName] = module
        self._server[moduleName] = module

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
                nil,
                function(subModuleName, localModules)
                    self:_verifySharedModuleName(subModuleName, localModules)
                end,
                self._services,
                true
            )
            table.move(nestedModules, 1, #nestedModules, #sharedModules + 1, sharedModules)
        end
    end

    return sharedModules
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

function ModuleLoader:_loadServerModules(): { CrosswalkModule }
    local self = self :: ModuleLoader & Private

    local serverModules = {}

    for _, moduleScript in self._serverScripts do
        local moduleName = moduleScript.Name
        self._reporter:debug('loading server module `%s`', moduleName)

        self:_verifyServerModuleName(moduleName, self._server)

        local localServerModules = nil
        if self._useRecursiveMode then
            localServerModules = table.clone(self._shared)
            self._localModules[moduleScript] = localServerModules
        else
            localServerModules = self._server
        end

        local api = {}

        local module =
            self._requireModule(moduleScript, localServerModules, self._client, self._services)

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

        for name, newFunction in pairs(api) do
            module[name] = newFunction
        end

        self._server[moduleName] = module
        table.insert(serverModules, module)
    end

    if self._useRecursiveMode then
        for _, moduleScript in self._serverScripts do
            local localServerModules = self._localModules[moduleScript]

            for name, content in self._server do
                if self._shared[name] == nil then
                    localServerModules[name] = content
                end
            end

            local nestedModules = loadNestedModules(
                moduleScript,
                self._reporter,
                self._requireModule,
                self._localModules,
                self._shared,
                function(subModuleName, localModules)
                    self:_verifyServerModuleName(subModuleName, localModules)
                end,
                self._client,
                self._services
            )
            table.move(nestedModules, 1, #nestedModules, #serverModules + 1, serverModules)
        end
    end

    return serverModules
end

function ModuleLoader:_setupClientRemotes()
    local self = self :: ModuleLoader & Private

    for _, moduleScript in self._clientScripts do
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
    for _, module in self._onlyServer do
        if module.OnPlayerReady then
            task.spawn(module.OnPlayerReady, player)
        end
    end
end

function ModuleLoader:onPlayerRemoving(player: Player)
    local self = self :: ModuleLoader & Private

    self._serverRemotes:clearPlayer(player)
    self._ranOnPlayerReady[player] = nil

    for _, module in self._onlyServer do
        if module.OnPlayerLeaving then
            task.spawn(module.OnPlayerLeaving, player)
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
        _onlyShared = {},
        _server = {},
        _onlyServer = {},
        _client = {},
        _external = options.external or {},
        _ranOnPlayerReady = {},
        _sharedScripts = options.shared,
        _serverScripts = options.server,
        _clientScripts = options.client,
        _serverRemotes = options.serverRemotes,
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
