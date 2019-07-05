local Services = require(script:WaitForChild('Services'))
local ServerRemotes = require(script:WaitForChild('ServerRemotes'))
local GetSecurity = require(script:WaitForChild('GetSecurity'))

local function requireModule(moduleScript, ...)
	local args = {...}
	local loaded, module = pcall(function()
		return require(moduleScript)(unpack(args))
	end)
	if loaded then
		return module
	else
		error(('Error while loading module %s : %s'):format(moduleScript.Name, module))
	end
end

return function(configuration)
	assert(configuration.ServerFolder, 'ServerFolder is not provided in configuration')
	assert(configuration.ClientFolder, 'ClientFolder is not provided in configuration')
	assert(configuration.SharedFolder, 'SharedFolder is not provided in configuration')

	local ServerModules = {}
	local SharedModules = {}
	local ClientModules = {}

	ServerRemotes.Init()

	for _, moduleScript in ipairs(configuration.SharedFolder:GetChildren()) do
		local module = requireModule(moduleScript, true, SharedModules, Services)
		SharedModules[moduleScript.Name] = module
		ServerModules[moduleScript.Name] = module

		if module.Init then
			module.Init()
		end
	end

	for _, moduleScript in ipairs(configuration.ServerFolder:GetChildren()) do
		local api = {}
		local module = requireModule(moduleScript, ServerModules, ClientModules, Services)

		for funcName, func in pairs(module) do
			if type(func) == 'function' then
				if funcName:match('_event$') then
					local name = funcName:match('^(.-)_')
					ServerRemotes.AddEventToServer(moduleScript.Name, name, func, GetSecurity(funcName))
					api[name] = function(...)
						return select(2, func(...))
					end

				elseif funcName:match('_func$') then
					local name = funcName:match('^(.-)_')
					ServerRemotes.AddFunctionToServer(moduleScript.Name, name, func, GetSecurity(funcName))
					api[name] = function(...)
						return select(2, func(...))
					end
				end
			end
		end

		for k, v in pairs(api) do
			module[k] = v
		end

		ServerModules[moduleScript.Name] = module

		if module.Init then
			module.Init()
		end
	end

	for _, moduleScript in ipairs(configuration.ClientFolder:GetChildren()) do
		local module = requireModule(moduleScript, {}, Services)

		local api = {}

		for funcName, func in pairs(module) do
			if type(func) == 'function' then
				if funcName:match('_event$') then
					local name = funcName:match('(.+)_event$')
					api[name], api[name .. 'All'] = ServerRemotes.AddEventToClient(moduleScript.Name, name)

				elseif funcName:match('_func$') then
					local name = funcName:match('(.+)_func$')
					api[name], api[name .. 'All'] = ServerRemotes.AddFunctionToClient(moduleScript.Name, name)
				end
			end
		end

		ClientModules[moduleScript.Name] = api
	end

	if configuration.ClientCallMaxDelay then
		assert(type(configuration.ClientCallMaxDelay) == 'number', 'ClientCallMaxDelay in configuration should be a number')
		ServerRemotes.SetClientCallMaxDelay(configuration.ClientCallMaxDelay)
	end

	ServerRemotes.ServerReady()

	for _, module in pairs(ServerModules) do
		if module.Start then
			module.Start()
		end
	end

	Services.Players.PlayerRemoving:Connect(function(player)
		for _, module in pairs(ServerModules) do
			if module.OnPlayerLeaving then
				spawn(function()
					module.OnPlayerLeaving(player)
				end)
			end
		end
	end)

	ServerRemotes.Subscribe('PlayerReady', function(player)
		for _, module in pairs(ServerModules) do
			if module.OnPlayerReady then
				spawn(function()
					module.OnPlayerReady(player)
				end)
			end
		end
	end)
end