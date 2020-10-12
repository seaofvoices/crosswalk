local Services = require(script:WaitForChild('Services'))
local ServerRemotes = require(script:WaitForChild('ServerRemotes'))
local GetSecurity = require(script:WaitForChild('GetSecurity'))

local function crosswalkError(message, ...)
	error(('crosswalk[server]: %s'):format(message:format(...)), 1)
end

local function crosswalkAssert(assertion, message, ...)
	if not assertion then
		crosswalkError(message, ...)
	end
end

local function requireModule(moduleScript, ...)
	local args = {...}
	local loaded, module = pcall(function()
		return require(moduleScript)(unpack(args))
	end)
	if loaded then
		return module
	else
		crosswalkError('Error while loading module %q : %s', moduleScript.Name, module)
	end
end

return function(configuration)
	crosswalkAssert(configuration.ServerModules, 'ServerModules is not provided in configuration')
	crosswalkAssert(configuration.ClientModules, 'ClientModules is not provided in configuration')
	crosswalkAssert(configuration.SharedModules, 'SharedModules is not provided in configuration')

	local serverModules = {}
	local sharedModules = {}
	local clientModules = {}

	ServerRemotes.Initialize()

	for _, moduleScript in ipairs(configuration.SharedModules) do
		local moduleName = moduleScript.Name

		crosswalkAssert(
			sharedModules[moduleName] == nil,
			'shared module named %q was already registered as a shared module',
			moduleName
		)

		local module = requireModule(moduleScript, sharedModules, Services, true)
		sharedModules[moduleName] = module
		serverModules[moduleName] = module
	end

	for _, moduleScript in ipairs(configuration.ServerModules) do
		local moduleName = moduleScript.Name

		crosswalkAssert(
			sharedModules[moduleName] == nil,
			'server module named %q was already registered as a shared module',
			moduleName
		)
		crosswalkAssert(
			serverModules[moduleName] == nil,
			'server module named %q was already registered as a server module',
			moduleName
		)

		local api = {}
		local module = requireModule(moduleScript, serverModules, clientModules, Services)

		for funcName, func in pairs(module) do
			if type(func) == 'function' then
				if funcName:match('_event$') then
					local name = funcName:match('^(.-)_')
					ServerRemotes.AddEventToServer(moduleName, name, func, GetSecurity(funcName))
					api[name] = function(...)
						return select(2, func(...))
					end

				elseif funcName:match('_func$') then
					local name = funcName:match('^(.-)_')
					ServerRemotes.AddFunctionToServer(moduleName, name, func, GetSecurity(funcName))
					api[name] = function(...)
						return select(2, func(...))
					end
				end
			end
		end

		for k, v in pairs(api) do
			module[k] = v
		end

		serverModules[moduleName] = module
	end

	for _, module in pairs(sharedModules) do
		if module.Init then
			module.Init()
		end
    end

	for name, module in pairs(serverModules) do
		if sharedModules[name] == nil and module.Init then
			module.Init()
		end
    end

	for _, moduleScript in ipairs(configuration.ClientModules) do
		local moduleName = moduleScript.Name

		crosswalkAssert(
			sharedModules[moduleName] == nil,
			'client module named %q was already registered as a shared module',
			moduleName
		)
		crosswalkAssert(
			serverModules[moduleName] == nil,
			'client module named %q was already registered as a server module',
			moduleName
		)
		crosswalkAssert(
			clientModules[moduleName] == nil,
			'client module named %q was already registered as a client module',
			moduleName
		)

		local module = requireModule(moduleScript, {}, {}, Services)

		local api = {}

		for funcName, func in pairs(module) do
			if type(func) == 'function' then
				if funcName:match('_event$') then
					local name = funcName:match('(.+)_event$')
					local nameForAll = name .. 'All'

					crosswalkAssert(
						module[nameForAll] == nil,
						'module named %q already has a function named %q',
						moduleName
					)

					api[name], api[name .. 'All'] = ServerRemotes.AddEventToClient(moduleName, name)

				elseif funcName:match('_func$') then
					local name = funcName:match('(.+)_func$')
					api[name], api[name .. 'All'] = ServerRemotes.AddFunctionToClient(moduleName, name)
				end
			end
		end

		clientModules[moduleName] = api
	end

	if configuration.ClientCallMaxDelay then
		crosswalkAssert(
			type(configuration.ClientCallMaxDelay) == 'number',
			'ClientCallMaxDelay in configuration should be a number'
		)
		ServerRemotes.SetClientCallMaxDelay(configuration.ClientCallMaxDelay)
	end

	ServerRemotes.ServerReady()

	for _, module in pairs(serverModules) do
		if module.Start then
			module.Start()
		end
	end

	Services.Players.PlayerRemoving:Connect(function(player)
		for _, module in pairs(serverModules) do
			if module.OnPlayerLeaving then
				coroutine.wrap(function()
					module.OnPlayerLeaving(player)
				end)()
			end
		end
	end)

	ServerRemotes.Subscribe('PlayerReady', function(player)
		for _, module in pairs(serverModules) do
			if module.OnPlayerReady then
				coroutine.wrap(function()
					module.OnPlayerReady(player)
				end)()
			end
		end
	end)
end
