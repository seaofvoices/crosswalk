--!nonstrict
local ClientServices = require('./ClientServices')
local requireModule = require('../Common/requireModule')
local Reporter = require('../Common/Reporter')
local validateSharedModule = require('../Common/validateSharedModule')

local EVENT_PATTERN = '_event$'
local FUNCTION_PATTERN = '_func$'

local ClientModuleLoader = {}
local ClientModuleLoaderMetatable = { __index = ClientModuleLoader }

function ClientModuleLoader:loadModules()
    self.reporter:assert(
        not self._hasLoaded,
        'modules were already loaded once and cannot be loaded twice!'
    )

    self.clientRemotes:listen()

    for moduleName, externalModule in pairs(self.external) do
        self.reporter:debug('adding external module `%s`', moduleName)
        self.shared[moduleName] = externalModule
        self.client[moduleName] = externalModule
    end

    self.reporter:debug('loading shared modules')
    local onlySharedModules = self:_loadSharedModules()

    self.reporter:debug('loading client modules')
    local onlyClientModules = self:_loadClientModules()

    self.reporter:debug('calling `Init` for shared modules')
    for _, module in ipairs(onlySharedModules) do
        if module.Init then
            module.Init()
        end
    end

    self.reporter:debug('calling `Init` for client modules')
    for _, module in ipairs(onlyClientModules) do
        if module.Init then
            module.Init()
        end
    end

    self.reporter:debug('calling `Start` for shared modules')
    for _, module in ipairs(onlySharedModules) do
        if module.Start then
            module.Start()
        end
    end

    self.reporter:debug('calling `Start` for client modules')
    for _, module in ipairs(onlyClientModules) do
        if module.Start then
            module.Start()
        end
    end

    self.clientRemotes:fireReadyRemote()

    self.reporter:debug('calling `OnPlayerReady` for client modules')
    for _, module in ipairs(onlyClientModules) do
        if module.OnPlayerReady then
            task.spawn(module.OnPlayerReady, self.player)
        end
    end

    self._hasLoaded = true
end

function ClientModuleLoader:_loadSharedModules()
    local sharedModules = {}
    for _, moduleScript in ipairs(self.sharedScripts) do
        local moduleName = moduleScript.Name
        self.reporter:debug('loading shared module `%s`', moduleName)

        self.reporter:assert(
            self.external[moduleName] == nil,
            'shared module named %q was already provided as an external client module. Rename '
                .. 'the shared module or the external module',
            moduleName
        )
        self.reporter:assert(
            self.shared[moduleName] == nil,
            'shared module named %q was already registered as a shared module',
            moduleName
        )

        local module = self.requireModule(moduleScript, self.shared, self.services, false)

        if _G.DEV then
            validateSharedModule(module, moduleName, self.reporter)
        end

        self.shared[moduleName] = module
        self.client[moduleName] = module
        table.insert(sharedModules, module)
    end
    return sharedModules
end

function ClientModuleLoader:_loadClientModules()
    local clientModules = {}
    local serverModules = self.clientRemotes:getServerModules()

    for _, moduleScript in ipairs(self.clientScripts) do
        local moduleName = moduleScript.Name
        self.reporter:debug('loading client module `%s`', moduleName)

        self.reporter:assert(
            self.external[moduleName] == nil,
            'client module named %q was already provided as an external client module. Rename '
                .. 'the client module or the external module',
            moduleName
        )
        self.reporter:assert(
            self.shared[moduleName] == nil,
            'client module named %q was already registered as a shared module',
            moduleName
        )
        self.reporter:assert(
            self.client[moduleName] == nil,
            'client module named %q was already registered as a client module',
            moduleName
        )

        local api = {}
        local module = self.requireModule(moduleScript, self.client, serverModules, self.services)

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
                    self.clientRemotes:connectRemote(moduleName, name, callback)
                end
            end
        end

        for name, newFunction in pairs(api) do
            module[name] = newFunction
        end

        self.client[moduleName] = module
        table.insert(clientModules, module)
    end

    return clientModules
end

local function new(options)
    return setmetatable({
        _hasLoaded = false,
        shared = {},
        client = {},
        external = options.external or {},
        sharedScripts = options.shared,
        clientScripts = options.client,
        player = options.player,
        clientRemotes = options.clientRemotes,
        requireModule = options.requireModule or requireModule,
        reporter = options.reporter or Reporter.default(),
        services = options.services or ClientServices,
    }, ClientModuleLoaderMetatable)
end

return {
    new = new,
}
