return function(ServerRemotes, private)
	return function(module, functionName, func, security)
		security = security or 'High'

		private.nameServerMap[module] = true

		local remote = Instance.new('RemoteFunction')
		remote.Parent = private.remoteFolder

		local id = private.GetUniqueId()
		local name = private.GetRemoteName(module, functionName)
		private.nameIdMap[name] = id
		remote.Name = id

		private.remotesToServer[module] = private.remotesToServer[module] or {}
		private.remotesToServer[module][functionName] = remote
		private.nameSecurityMap[name] = security

		if security == 'None' then
			function remote.OnServerInvoke(plr, ...)
				local results = {func(plr, ...)}
				if results[1] then
					return unpack(results, 2)
				else
					private.onFunctionError(plr, module, functionName)
				end
			end

		elseif security == 'High' then
			function remote.OnServerInvoke(plr, key, ...)
				if private.VerifyKey(plr, module, functionName, key) then
					local key = private.NewKey(plr, module, functionName)
					private.keySender:FireClient(plr, key, module, functionName)
					local results = {func(plr, ...)}
					if results[1] then
						return unpack(results, 2)
					else
						private.onFunctionError(plr, module, functionName)
					end
				end
			end

		elseif security == 'Low' then
			function remote.OnServerInvoke(plr, key, ...)
				if private.VerifyKey(plr, module, functionName, key) then
					local results = {func(plr, ...)}
					if results[1] then
						return unpack(results, 2)
					else
						private.onFunctionError(plr, module, functionName)
					end
				end
			end
		else
			error(('Unknown security level <%s>. Valid options are: High, Low or None'):format(tostring(security)))
		end
	end
end