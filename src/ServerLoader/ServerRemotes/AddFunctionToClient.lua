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

		return function(plr, ...)
			assert(plr:IsA('Player'), 'plr has to be a Player')
			return remote:InvokeClient(plr, ...)
		end, function(...)
			local args = {...}
			local results = {}
			local totalPlayers = 0
			local totalResults = 0
			for plr in ipairs(private.playerKeys) do
				totalPlayers = totalPlayers + 1
				spawn(function()
					results[plr] = remote:InvokeClient(plr, unpack(args))
					totalResults = totalResults + 1
				end)
			end
			local startTime = tick()
			repeat
				wait()
			until totalResults == totalPlayers or (tick() - startTime) > private.remoteCallMaxDelay
			return totalResults == totalPlayers, results
		end
	end
end