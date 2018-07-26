return function(ServerRemotes, private)
	return function(plr)
		local keys = {}
		local names = {}
		local waitForNames = {}

		for moduleName, functions in pairs(private.remotesToServer) do
			names[moduleName] = {}
			waitForNames[moduleName] = {}
			keys[moduleName] = {}

			for funcName in pairs(functions) do
				local name = private.GetRemoteName(moduleName, funcName)

				if private.nameSecurityMap[name] ~= 'None' then
					keys[moduleName][funcName] = private.GetKey()
				end

				names[moduleName][funcName] = private.nameIdMap[name]

				if private.nameSecurityMap[name] == 'High' then
					waitForNames[moduleName][funcName] = true
				end
			end
		end

		for moduleName, functions in pairs(private.remotesToClient) do
			if names[moduleName] then
				error(('Server modules and client modules can not have the same name [%s].'):format(moduleName))
			end

			names[moduleName] = {}

			for funcName in pairs(functions) do
				local name = private.GetRemoteName(moduleName, funcName)
				names[moduleName][funcName] = private.nameIdMap[name]
			end
		end

		private.playerKeys[plr] = keys

		return {
			Keys = keys,
			Names = names,
			WaitForKeyNames = waitForNames,
			NameServerMap = private.nameServerMap
		}
	end
end