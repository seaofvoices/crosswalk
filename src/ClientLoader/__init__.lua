local Services = require(script:WaitForChild('ClientServices'))
local ClientRemotes = require(script:WaitForChild('ClientRemotes'))

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
	assert(configuration.ClientFolder, 'ClientFolder is not provided in configuration')
	assert(configuration.SharedFolder, 'SharedFolder is not provided in configuration')

	local ClientModules = {}
	local SharedModules = {}
	local ServerModules = {}

	ClientRemotes.Init(ServerModules)

	for _, moduleScript in ipairs(configuration.SharedFolder:GetChildren()) do
		local module = requireModule(moduleScript, false, SharedModules, Services)
		SharedModules[moduleScript.Name] = module
		ClientModules[moduleScript.Name] = module

		if module.Init then
			module.Init()
		end
	end

	for _, moduleScript in ipairs(configuration.ClientFolder:GetChildren()) do
		local api = {}
		local module = require(moduleScript)(ClientModules, ServerModules, Services)

		for funcName, func in pairs(module) do
			if type(func) == 'function' then
				if funcName:match('_event$') then
					local name = funcName:match('(.+)_event$')
					api[name] = func
					ClientRemotes.ConnectRemote(moduleScript.Name, name, func)

				elseif funcName:match('_func$') then
					local name = funcName:match('(.+)_func$')
					api[name] = func
					ClientRemotes.ConnectRemote(moduleScript.Name, name, func)
				end
			end
		end

		for k, v in pairs(api) do
			module[k] = v
		end

		ClientModules[moduleScript.Name] = module

		if module.Init then
			module.Init()
		end
	end

	for _, module in pairs(ClientModules) do
		if module.Start then
			module.Start()
		end
	end
end