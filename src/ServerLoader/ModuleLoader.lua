local getSecurity = require('./getSecurity')
local Services = require('./Services')
local Reporter = require('../Common/Reporter')
local requireModule = require('../Common/requireModule')
local validateSharedModule = require('../Common/validateSharedModule')
local extractFunctionName = require('../Common/extractFunctionName')

local EVENT_PATTERN = '_event$'
local FUNCTION_PATTERN = '_func$'

local function validateReturnedValues(values, reporter, context)
    local validated = values[1]
    if typeof(validated) ~= 'boolean' then
        reporter:warn(
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
        reporter:warn(
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

local ModuleLoader = {}
local ModuleLoaderMetatable = { __index = ModuleLoader }

function ModuleLoader:loadModules()
    self.reporter:assert(
        not self._hasLoaded,
        'modules were already loaded once and cannot be loaded twice!'
    )

    for moduleName, externalModule in pairs(self.external) do
        self.reporter:debug('adding external module `%s`', moduleName)
        self.shared[moduleName] = externalModule
        self.server[moduleName] = externalModule
    end

    self.reporter:debug('loading shared modules')
    local onlySharedModules = self:_loadSharedModules()

    self.reporter:debug('loading server modules')
    local onlyServerModules = self:_loadServerModules()

    self.reporter:debug('calling `Init` for shared modules')
    for _, module in ipairs(onlySharedModules) do
        if module.Init then
            module.Init()
        end
    end

    self.reporter:debug('calling `Init` for server modules')
    for _, module in ipairs(onlyServerModules) do
        if module.Init then
            module.Init()
        end
    end

    self.reporter:debug('setup remotes for client modules')
    self:_setupClientRemotes()

    self.reporter:debug('calling `Start` for shared modules')
    for _, module in ipairs(onlySharedModules) do
        if module.Start then
            module.Start()
        end
    end

    self.reporter:debug('calling `Start` for server modules')
    for _, module in ipairs(onlyServerModules) do
        if module.Start then
            module.Start()
        end
    end

    self._hasLoaded = true
end

function ModuleLoader:_loadSharedModules()
    local sharedModules = {}

    for _, moduleScript in ipairs(self.sharedScripts) do
        local moduleName = moduleScript.Name
        self.reporter:debug('loading shared module `%s`', moduleName)

        self.reporter:assert(
            self.external[moduleName] == nil,
            'shared module named %q was already provided as an external server module. Rename '
                .. 'the shared module or the external module',
            moduleName
        )
        self.reporter:assert(
            self.shared[moduleName] == nil,
            'shared module named %q was already registered as a shared module',
            moduleName
        )

        local module = self.requireModule(moduleScript, self.shared, self.services, true)

        if _G.DEV then
            validateSharedModule(module, moduleName, self.reporter)
        end

        self.shared[moduleName] = module
        self.server[moduleName] = module
        table.insert(sharedModules, module)
    end

    return sharedModules
end

function ModuleLoader:_loadServerModules()
    local serverModules = {}

    for _, moduleScript in ipairs(self.serverScripts) do
        local moduleName = moduleScript.Name
        self.reporter:debug('loading server module `%s`', moduleName)

        self.reporter:assert(
            self.external[moduleName] == nil,
            'server module named %q was already provided as an external server module. Rename '
                .. 'the server module or the external module',
            moduleName
        )
        self.reporter:assert(
            self.shared[moduleName] == nil,
            'server module named %q was already registered as a shared module',
            moduleName
        )
        self.reporter:assert(
            self.server[moduleName] == nil,
            'server module named %q was already registered as a server module',
            moduleName
        )

        local api = {}
        local module = self.requireModule(moduleScript, self.server, self.client, self.services)

        for functionName, func in pairs(module) do
            if type(func) == 'function' then
                local name = nil
                local serverToServerFunction = nil

                if functionName:match(EVENT_PATTERN) then
                    name = extractFunctionName(functionName)
                    self.serverRemotes:addEventToServer(
                        moduleName,
                        name,
                        func,
                        getSecurity(functionName)
                    )
                    serverToServerFunction = function(...)
                        if _G.DEV then
                            local values = table.pack(func(...))
                            validateReturnedValues(values, self.reporter, {
                                moduleName = moduleName,
                                functionName = functionName,
                                moduleFunction = func,
                            })

                            if values.n > 1 then
                                self.reporter:warn(
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
                    self.serverRemotes:addFunctionToServer(
                        moduleName,
                        name,
                        func,
                        getSecurity(functionName)
                    )
                    serverToServerFunction = function(...)
                        if _G.DEV then
                            local values = table.pack(func(...))
                            validateReturnedValues(values, self.reporter, {
                                moduleName = moduleName,
                                functionName = functionName,
                                moduleFunction = func,
                            })

                            return unpack(values, 2, values.n)
                        else
                            return select(2, func(...))
                        end
                    end
                end

                if name then
                    self.reporter:assert(
                        api[name] == nil,
                        'server module named %q has defined two functions that resolves to the '
                            .. 'same name `%s`. Rename one of them or remove an unused one',
                        moduleName,
                        name
                    )
                    self.reporter:assert(
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

        self.server[moduleName] = module
        table.insert(serverModules, module)
    end

    return serverModules
end

function ModuleLoader:_setupClientRemotes()
    for _, moduleScript in ipairs(self.clientScripts) do
        local moduleName = moduleScript.Name

        self.reporter:assert(
            self.shared[moduleName] == nil,
            'client module named %q was already registered as a shared module',
            moduleName
        )
        self.reporter:assert(
            self.server[moduleName] == nil,
            'client module named %q was already registered as a server module',
            moduleName
        )
        self.reporter:assert(
            self.client[moduleName] == nil,
            'client module named %q was already registered as a client module',
            moduleName
        )

        local module = self.requireModule(moduleScript, {}, {}, Services)

        local api = {}

        for functionName, func in pairs(module) do
            if type(func) == 'function' then
                local name = nil
                local callClient = nil
                local callAllClients = nil

                if functionName:match('_event$') then
                    name = functionName:match('(.+)_event$')
                    callClient, callAllClients =
                        self.serverRemotes:addEventToClient(moduleName, name)
                elseif functionName:match('_func$') then
                    name = functionName:match('(.+)_func$')
                    callClient, callAllClients =
                        self.serverRemotes:addFunctionToClient(moduleName, name)
                end

                if name then
                    self.reporter:assert(
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
                    self.reporter:assert(
                        module[name] == nil,
                        'client module named %q already has a %s named `%s` that collides '
                            .. 'with the generated function from `%s`',
                        moduleName,
                        typeof(api[name]) == 'function' and 'function' or 'value',
                        name,
                        functionName
                    )
                    self.reporter:assert(
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

        self.client[moduleName] = api
    end
end

function ModuleLoader:onPlayerReady(player)
    self.reporter:assert(
        self.ranOnPlayerReady[player] == nil,
        'onPlayerReady was already called for player %q',
        player.Name
    )
    self.ranOnPlayerReady[player] = true
    for name, module in pairs(self.server) do
        if self.shared[name] == nil and module.OnPlayerReady then
            task.spawn(module.OnPlayerReady, player)
        end
    end
end

function ModuleLoader:onPlayerRemoving(player)
    self.serverRemotes:clearPlayer(player)
    self.ranOnPlayerReady[player] = nil

    for name, module in pairs(self.server) do
        if self.shared[name] == nil and module.OnPlayerLeaving then
            task.spawn(module.OnPlayerLeaving, player)
        end
    end
end

function ModuleLoader:onUnapprovedExecution(player, moduleName, functionName)
    local module = self.server[moduleName]
    self.reporter:assert(
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

function ModuleLoader:hasLoaded()
    return self._hasLoaded
end

local function new(options)
    return setmetatable({
        _hasLoaded = false,
        shared = {},
        server = {},
        client = {},
        external = options.external or {},
        ranOnPlayerReady = {},
        sharedScripts = options.shared,
        serverScripts = options.server,
        clientScripts = options.client,
        serverRemotes = options.serverRemotes,
        reporter = options.reporter or Reporter.default(),
        services = options.services or Services,
        requireModule = options.requireModule or requireModule,
    }, ModuleLoaderMetatable)
end

return {
    new = new,
}
