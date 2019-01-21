return function(ServerRemotes, private)
	return function(moduleName, functionName)
		private.nameServerMap[moduleName] = false

		local remote = Instance.new('RemoteFunction')
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
				return remote:InvokeClient(player, ...)
			end
		end, function(...)
			local args = {...}
			local results = {}
			local totalPlayers = 0
			local totalResults = 0

			for player in ipairs(private.playerKeys) do
				if private.isPlayerReadyMap[player] then
					totalPlayers = totalPlayers + 1
					spawn(function()
						results[player] = remote:InvokeClient(player, unpack(args))
						totalResults = totalResults + 1
					end)
				end
			end

			local startTime = tick()
			repeat
				wait()
			until totalResults == totalPlayers or (tick() - startTime) > private.remoteCallMaxDelay

			return totalResults == totalPlayers, results
		end
	end
end