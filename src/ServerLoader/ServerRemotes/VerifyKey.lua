return function(ServerRemotes, private)
	return function(plr, moduleName, functionName, key)
		if private.playerKeys[plr] then
			if private.playerKeys[plr][moduleName] then
				if private.playerKeys[plr][moduleName][functionName] then
					if key == private.playerKeys[plr][moduleName][functionName] then
						return true
					else
						private.onKeyError(plr, moduleName, functionName)
						return false
					end
				else
					warn(('No key found for <%s.%s> set for player <%s>'):format(plr.Name, moduleName, functionName))
				end
			else
				warn(('No key found for module <%s> for player <%s>'):format(moduleName, plr.Name))
			end
		else
			warn(('No key set for player <%s>'):format(plr.Name))
		end

		private.onKeyMissing(plr, moduleName, functionName)

		return false
	end
end