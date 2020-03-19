local ReplicatedStorage = game:GetService('ReplicatedStorage')

return function(ClientRemotes, private)
	return function(serverModules)
		local remoteFolder = ReplicatedStorage:WaitForChild('Remotes')

		private.currentKeys = nil
		private.waitForKeyNames = {}
		private.yieldNames = {}
		private.remotes = {}

		private.serverModules = serverModules

		for _, remote in ipairs(remoteFolder:GetChildren()) do
			if remote.Name:match('^[^ ]*  $') then
				local data = remote:InvokeServer()
				private.currentKeys = data.Keys
				private.waitForKeyNames = data.WaitForKeyNames

				for moduleName, functions in pairs(data.Names) do
					private.remotes[moduleName] = {}

					if data.NameServerMap[moduleName] then
						serverModules[moduleName] = {}
						private.yieldNames[moduleName] = {}

						for functionName, id in pairs(functions) do
							local functionRemote = remoteFolder:WaitForChild(id)
							private.remotes[moduleName][functionName] = functionRemote

							if functionRemote:IsA('RemoteEvent') then
								serverModules[moduleName][functionName] = private.GetFireRemoteEvent(
									moduleName,
									functionName,
									functionRemote,
									private.currentKeys[moduleName][functionName] ~= nil
								)
							else
								serverModules[moduleName][functionName] = private.GetFireRemoteFunction(
									moduleName,
									functionName,
									functionRemote,
									private.currentKeys[moduleName][functionName] ~= nil
								)
							end
						end
					else
						for functionName, id in pairs(functions) do
							private.remotes[moduleName][functionName] = remoteFolder:WaitForChild(id)
						end
					end
				end
			elseif remote.Name:match('^[^ ]*   $') then
				remote.OnClientEvent:Connect(function(newKey, moduleName, funcName)
					private.currentKeys[moduleName][funcName] = newKey
					private.yieldNames[moduleName][funcName] = nil
				end)
			end
		end
	end
end