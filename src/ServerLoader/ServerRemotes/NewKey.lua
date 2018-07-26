return function(ServerRemotes, private)
	return function(plr, moduleName, functionName)
		local key = private.GetKey()
		private.playerKeys[plr][moduleName][functionName] = key
		return key
	end
end