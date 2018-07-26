return function(ClientRemotes, private)
	return function(module, funcName)
		repeat wait() until not private.yieldNames[module][funcName]
	end
end
