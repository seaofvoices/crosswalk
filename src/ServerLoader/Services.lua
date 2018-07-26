return setmetatable({
	Lighting = game:GetService('Lighting'),
	HttpService = game:GetService('HttpService'),
	Players = game:GetService('Players'),
	ReplicatedStorage = game:GetService('ReplicatedStorage'),
	ServerStorage = game:GetService('ServerStorage'),
	SoundService = game:GetService('SoundService'),
	Workspace = game:GetService('Workspace')
}, {__index = function(t, service)
	t[service] = game:GetService(service)
	return t[service]
end})