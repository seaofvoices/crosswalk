return function(ServerRemotes, private)
	local Players = game:GetService('Players')

	return function()
		private.remoteFolder = Instance.new('Folder')
		private.remoteFolder.Name = 'Remotes'

		private.nameIdMap = {}
		private.nameSecurityMap = {}
		private.nameServerMap = {}
		private.remotesToClient = {}
		private.remotesToServer = {}
		private.playerKeys = {}
		private.remoteCallMaxDelay = 2
		private.isPlayerReadyMap = {}

		private.onKeyError = function(plr, moduleName, functionName)
			warn(('Player <%s> (id:%d) sent a wrong key to %s.%s'):format(
				plr.Name, plr.UserId, moduleName, functionName
			))
		end

		private.onFunctionError = function(plr, moduleName, functionName)
			warn(('Function %s.%s called by player <%s> (id:%d) was not approved'):format(
				moduleName, functionName, plr.Name, plr.UserId
			))
		end

		private.onSecondPlayerRequest = function(plr)
			warn(('Player <%s> (id:%d) is asking again for remote Ids and keys.'):format(plr.Name, plr.UserId))
		end

		private.onKeyMissing = function(plr, moduleName, functionName)
			warn(('Player <%s> (id:%d) forgot to send a key when calling %s.%s().'):format(
				plr.Name,
				plr.UserId,
				moduleName,
				functionName
			))
		end

		private.onPlayerReady = nil

		private.dataSender = Instance.new('RemoteFunction')
		private.dataSender.Name = private.GetUniqueId() .. '  '
		function private.dataSender.OnServerInvoke(plr)
			if not private.IsRemoteDataSent(plr) then
				return private.GetRemoteData(plr)
			else
				private.onSecondPlayerRequest(plr)
			end
		end
		private.dataSender.Parent = private.remoteFolder

		private.keySender = Instance.new('RemoteEvent')
		private.keySender.Name = private.GetUniqueId() .. '   '
		private.keySender.Parent = private.remoteFolder

		private.playerReady = Instance.new('RemoteEvent')
		private.playerReady.Name = private.GetUniqueId() .. '    '
		private.playerReady.OnServerEvent:Connect(function(player)
			while not private.onPlayerReady do
				wait()
			end
			private.isPlayerReadyMap[player] = true
			private.onPlayerReady(player)
		end)
		private.playerReady.Parent = private.remoteFolder

		Players.PlayerRemoving:Connect(function(player)
			private.isPlayerReadyMap[player] = nil
		end)
	end
end