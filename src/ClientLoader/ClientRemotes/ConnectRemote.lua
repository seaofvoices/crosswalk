return function(ClientRemotes, private)
	return function(module, name, func)
		if private.remotes[module] and private.remotes[module][name] then
			local remote = private.remotes[module][name]
			if remote:IsA('RemoteEvent') then
				remote.OnClientEvent:Connect(func)
			else
				remote.OnClientInvoke = func
			end
		else
			error(('Can not find remote from module <%s> and function <%s>'):format(module, name))
		end
	end
end
