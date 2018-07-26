return setmetatable({
	Lighting = game:GetService('Lighting'),
	HttpService = game:GetService('HttpService'),
	Players = game:GetService('Players'),
	ReplicatedFirst = game:GetService('ReplicatedFirst'),
	ReplicatedStorage = game:GetService('ReplicatedStorage'),
	RunService = game:GetService('RunService'),
	SoundService = game:GetService('SoundService'),
	Workspace = game:GetService('Workspace')
}, {__index = function(t, service)
	t[service] = game:GetService(service)
	return t[service]
end})