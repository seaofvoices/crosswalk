return function(ServerRemotes, private)
	return function(module, functionName, func, security)
		security = security or 'High'

		private.nameServerMap[module] = true

		local remote = Instance.new('RemoteEvent')
		remote.Parent = private.remoteFolder

		local id = private.GetUniqueId()
		local name = private.GetRemoteName(module, functionName)
		private.nameIdMap[name] = id
		remote.Name = id

		private.remotesToServer[module] = private.remotesToServer[module] or {}
		private.remotesToServer[module][functionName] = remote
		private.nameSecurityMap[name] = security

		if security == 'None' then
			remote.OnServerEvent:Connect(function(plr, ...)
				if not func(plr, ...) then
					private.onFunctionError(plr, module, functionName)
				end
			end)
		else
			if security == 'High' then
				remote.OnServerEvent:Connect(function(plr, key, ...)
					if private.VerifyKey(plr, module, functionName, key) then
						local key = private.NewKey(plr, module, functionName)
						private.keySender:FireClient(plr, key, module, functionName)
						if not func(plr, ...) then
							private.onFunctionError(plr, module, functionName)
						end
					end
				end)

			elseif security == 'Low' then
				remote.OnServerEvent:Connect(function(plr, key, ...)
					if private.VerifyKey(plr, module, functionName, key) then
						if not func(plr, ...) then
							private.onFunctionError(plr, module, functionName)
						end
					end
				end)
			end
		end
	end
end