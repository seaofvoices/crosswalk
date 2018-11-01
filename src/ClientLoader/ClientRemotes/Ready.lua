local ReplicatedStorage = game:GetService('ReplicatedStorage')

return function(ClientRemotes, private)
    local remoteFolder = ReplicatedStorage:WaitForChild('Remotes')

	return function()
		for _, remote in ipairs(remoteFolder:GetChildren()) do
			if remote.Name:match('^[^ ]*    $') then
                remote:FireServer()
                return
			end
		end
	end
end