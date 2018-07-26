return function(ServerRemotes, private)
	return function()
		private.remoteFolder.Parent = game:GetService('ReplicatedStorage')
	end
end