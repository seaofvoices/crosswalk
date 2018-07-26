return function(ClientRemotes, private)
	return function(module, funcName, remote, withKey)
		if withKey then
			if private.waitForKeyNames[module][funcName] then
				return function(...)
					if not private.yieldNames[module][funcName] then
						private.yieldNames[module][funcName] = true
						local result = remote:InvokeServer(private.currentKeys[module][funcName], ...)
						private.YieldUntilNewKey(module, funcName)
						return result
					else
						warn(('Call to <%s.%s.> skipped because client did not receive a new key yet'):format(module, funcName))
					end
				end
			else
				return function(...)
					return remote:InvokeServer(private.currentKeys[module][funcName], ...)
				end
			end
		else
			return function(...)
				return remote:InvokeServer(...)
			end
		end
	end
end
