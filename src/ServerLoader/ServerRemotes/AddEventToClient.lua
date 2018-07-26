return function(ServerRemotes, private)
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

		return function(plr, ...)
			assert(plr:IsA('Player'), 'plr has to be a Player')
			remote:FireClient(plr, ...)
		end, function(...)
			remote:FireAllClients(...)
		end
	end
end