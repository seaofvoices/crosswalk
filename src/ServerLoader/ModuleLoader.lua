local getSecurity = require(script.Parent.getSecurity)
local Reporter = require(script.Parent.Reporter)
local Services = require(script.Parent.Services)

local function requireModule(moduleScript, ...)
    local success, moduleLoader = pcall(require, moduleScript)
    if not success then
        error(('Error while loading module %q : %s'):format(moduleScript.Name, moduleLoader))
    end

    local loaded, module = pcall(moduleLoader, ...)
    if not loaded then
        error(('Error while calling the module loader %q : %s'):format(moduleScript.Name, module))
    end

    return module
end

local EVENT_PATTERN = '_event$'
local FUNCTION_PATTERN = '_func$'
local SPECIAL_FUNCTIONS = {
    OnPlayerReady = { server = true, client = true },
    OnPlayerLeaving = { server = true },
    OnUnapprovedExecution = { server = true },
}

local function extractFunctionName(name)
    return name:match('^(.-)_')
end

local ModuleLoader = {}
local ModuleLoaderMetatable = { __index = ModuleLoader }

function ModuleLoader:loadModules()
    self.reporter:assert(
        not self._hasLoaded,
        'modules were already loaded once and cannot be loaded twice!'
    )

    self.reporter:debug('loading shared modules')
    for _, moduleScript in ipairs(self.sharedScripts) do
        local moduleName = moduleScript.Name

        self.reporter:assert(
            self.shared[moduleName] == nil,
            'shared module named %q was already registered as a shared module',
            moduleName
        )

        local module = self.requireModule(moduleScript, self.shared, self.services, true)

        if _G.DEV then
            for property, value in pairs(module) do
                if
                    (property:match(EVENT_PATTERN) or property:match(FUNCTION_PATTERN))
                    and typeof(value) == 'function'
                then
                    self.reporter:warn(
                        'shared module %q has a function %q that is meant to exist on client or server modules. '
                            .. 'It should probably be renamed to %q',
                        moduleName,
                        property,
                        extractFunctionName(property)
                    )
                end
            end

            for functionName, info in pairs(SPECIAL_FUNCTIONS) do
                if module[functionName] then
                    local destination = {}
                    if info.server then
                        table.insert(destination, 'a server module')
                    end
                    if info.client then
                        table.insert(destination, 'a client module')
                    end

                    local messageEnd = ''

                    if #destination == 1 then
                        messageEnd = ' into ' .. destination[1]
                    elseif #destination > 1 then
                        local last = table.remove(destination)
                        messageEnd = (' into %s or %s'):format(
                            table.concat(destination, ', '),
                            last
                        )
                    end

                    self.reporter:warn(
                        'shared module %q has a `%s` function defined that will not be called automatically. '
                            .. 'This function should be removed or the logic should be moved%s.',
                        moduleName,
                        functionName,
                        messageEnd
                    )
                end
            end
        end

        self.shared[moduleName] = module
        self.server[moduleName] = module
    end

    self.reporter:debug('loading server modules')
    for _, moduleScript in ipairs(self.serverScripts) do
        local moduleName = moduleScript.Name

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

        for funcName, func in pairs(module) do
            if type(func) == 'function' then
                if funcName:match(EVENT_PATTERN) then
                    local name = extractFunctionName(funcName)
                    self.serverRemotes:addEventToServer(
                        moduleName,
                        name,
                        func,
                        getSecurity(funcName)
                    )
                    api[name] = function(...)
                        return select(2, func(...))
                    end
                elseif funcName:match(FUNCTION_PATTERN) then
                    local name = extractFunctionName(funcName)
                    self.serverRemotes:addFunctionToServer(
                        moduleName,
                        name,
                        func,
                        getSecurity(funcName)
                    )
                    api[name] = function(...)
                        return select(2, func(...))
                    end
                end
            end
        end

        for k, v in pairs(api) do
            module[k] = v
        end

        self.server[moduleName] = module
    end

    self.reporter:debug('calling `Init` for shared modules')
    for _, module in pairs(self.shared) do
        if module.Init then
            module.Init()
        end
    end

    self.reporter:debug('calling `Init` for server modules')
    for name, module in pairs(self.server) do
        if self.shared[name] == nil and module.Init then
            module.Init()
        end
    end

    self.reporter:debug('setup remotes for client modules')
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

        for funcName, func in pairs(module) do
            if type(func) == 'function' then
                if funcName:match('_event$') then
                    local name = funcName:match('(.+)_event$')
                    local nameForAll = name .. 'All'

                    self.reporter:assert(
                        module[nameForAll] == nil,
                        'module named %q already has a function named %q',
                        moduleName
                    )

                    api[name], api[name .. 'All'] = self.serverRemotes:addEventToClient(
                        moduleName,
                        name
                    )
                elseif funcName:match('_func$') then
                    local name = funcName:match('(.+)_func$')
                    api[name], api[name .. 'All'] = self.serverRemotes:addFunctionToClient(
                        moduleName,
                        name
                    )
                end
            end
        end

        self.client[moduleName] = api
    end

    self.reporter:debug('calling `Start` for shared modules')
    for _, module in pairs(self.shared) do
        if module.Start then
            module.Start()
        end
    end

    self.reporter:debug('calling `Start` for server modules')
    for name, module in pairs(self.server) do
        if self.shared[name] == nil and module.Start then
            module.Start()
        end
    end

    self._hasLoaded = true
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
