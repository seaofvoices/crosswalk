return function(ServerRemotes, private)
	return function(plr)
		return private.playerKeys[plr] ~= nil
	end
end