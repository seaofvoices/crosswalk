local Players = game:GetService('Players')

local Services = require(script:WaitForChild('ClientServices'))
local ClientRemotes = require(script:WaitForChild('ClientRemotes'))

local function crosswalkError(message, ...)
	error(('crosswalk[client]: %s'):format(message:format(...)), 1)
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
	crosswalkAssert(configuration.ClientModules, 'ClientModules is not provided in configuration')
	crosswalkAssert(configuration.SharedModules, 'SharedModules is not provided in configuration')

	local clientModules = {}
	local sharedModules = {}
	local serverModules = {}

	ClientRemotes.Initialize(serverModules)

	for _, moduleScript in ipairs(configuration.SharedModules) do
		local moduleName = moduleScript.Name

		crosswalkAssert(
			sharedModules[moduleName] == nil,
			'shared module named %q was already registered as a shared module',
			moduleName
		)

		local module = requireModule(moduleScript, sharedModules, Services, false)
		sharedModules[moduleName] = module
		clientModules[moduleName] = module

		if module.Init then
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
			clientModules[moduleName] == nil,
			'client module named %q was already registered as a client module',
			moduleName
		)

		local api = {}
		local module = requireModule(moduleScript, clientModules, serverModules, Services)

		for funcName, func in pairs(module) do
			if type(func) == 'function' then
				if funcName:match('_event$') then
					local name = funcName:match('(.+)_event$')
					api[name] = func
					ClientRemotes.ConnectRemote(moduleName, name, func)

				elseif funcName:match('_func$') then
					local name = funcName:match('(.+)_func$')
					api[name] = func
					ClientRemotes.ConnectRemote(moduleName, name, func)
				end
			end
		end

		for k, v in pairs(api) do
			module[k] = v
		end

		clientModules[moduleName] = module

		if module.Init then
			module.Init()
		end
	end

	for _, module in pairs(clientModules) do
		if module.Start then
			module.Start()
		end
	end

	ClientRemotes.Ready()

	for _, module in pairs(clientModules) do
		if module.OnPlayerReady then
			spawn(function()
				module.OnPlayerReady(Players.LocalPlayer)
			end)
		end
	end
end
