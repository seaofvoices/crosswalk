return function(ServerRemotes, private)
	local Players = game:GetService('Players')

	return function(moduleName, functionName)
		private.nameServerMap[moduleName] = false

		local remote = Instance.new('RemoteEvent')
		remote.Parent = private.remoteFolder

		local id = private.GetUniqueId()
		local name = private.GetRemoteName(moduleName, functionName)
		private.nameIdMap[name] = id
		remote.Name = id

		private.remotesToClient[moduleName] = private.remotesToClient[moduleName] or {}
		private.remotesToClient[moduleName][functionName] = remote

		return function(player, ...)
			assert(
				typeof(player) == 'Instance' and player:IsA('Player'),
				('first argument must be a Player (in function call %s.%s)'):format(moduleName, functionName)
			)
			if private.isPlayerReadyMap[player] then
				remote:FireClient(player, ...)
			end
		end, function(...)
			for _, player in ipairs(Players:GetPlayers()) do
				if private.isPlayerReadyMap[player] then
					remote:FireClient(player, ...)
				end
			end
		end
	end
end