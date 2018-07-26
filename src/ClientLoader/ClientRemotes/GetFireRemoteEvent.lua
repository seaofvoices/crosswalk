return function(ClientRemotes, private)
	return function(module, funcName, remote, withKey)
		if withKey then
			if private.waitForKeyNames[module][funcName] then
				return function(...)
					if not private.yieldNames[module][funcName] then
						private.yieldNames[module][funcName] = true
						remote:FireServer(private.currentKeys[module][funcName], ...)
						private.YieldUntilNewKey(module, funcName)
					else
						warn(('Call to <%s.%s.> skipped because client did not receive a new key yet'):format(module, funcName))
					end
				end
			else
				return function(...)
					remote:FireServer(private.currentKeys[module][funcName], ...)
				end
			end
		else
			return function(...)
				remote:FireServer(...)
			end
		end
	end
end
