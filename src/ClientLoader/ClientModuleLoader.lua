local ClientLoaderModule = script.Parent
local Common = ClientLoaderModule:WaitForChild('Common')

local ClientServices = require(ClientLoaderModule:WaitForChild('ClientServices'))
local requireModule = require(Common:WaitForChild('requireModule'))
local Reporter = require(Common:WaitForChild('Reporter'))
local validateSharedModule = require(Common:WaitForChild('validateSharedModule'))

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

    self.reporter:debug('loading shared modules')
    self:_loadSharedModules()

    self.reporter:debug('loading client modules')
    self:_loadClientModules()

    self.reporter:debug('calling `Init` for shared modules')
    for _, module in pairs(self.shared) do
        if module.Init then
            module.Init()
        end
    end

    self.reporter:debug('calling `Init` for client modules')
    for name, module in pairs(self.client) do
        if self.shared[name] == nil and module.Init then
            module.Init()
        end
    end

    self.reporter:debug('calling `Start` for shared modules')
    for _, module in pairs(self.shared) do
        if module.Start then
            module.Start()
        end
    end

    self.reporter:debug('calling `Start` for client modules')
    for name, module in pairs(self.client) do
        if self.shared[name] == nil and module.Start then
            module.Start()
        end
    end

    self.clientRemotes:fireReadyRemote()

    self.reporter:debug('calling `OnPlayerReady` for client modules')
    for name, module in pairs(self.client) do
        if self.shared[name] == nil and module.OnPlayerReady then
            task.spawn(module.OnPlayerReady, self.player)
        end
    end

    self._hasLoaded = true
end

function ClientModuleLoader:_loadSharedModules()
    for _, moduleScript in ipairs(self.sharedScripts) do
        local moduleName = moduleScript.Name

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
    end
end

function ClientModuleLoader:_loadClientModules()
    local serverModules = self.clientRemotes:getServerModules()

    for _, moduleScript in ipairs(self.clientScripts) do
        local moduleName = moduleScript.Name

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
    end
end

local function new(options)
    return setmetatable({
        _hasLoaded = false,
        shared = {},
        client = {},
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
