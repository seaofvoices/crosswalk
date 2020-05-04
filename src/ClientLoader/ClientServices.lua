return setmetatable({
	Lighting = game:GetService('Lighting'),
	HttpService = game:GetService('HttpService'),
	Players = game:GetService('Players'),
	ReplicatedFirst = game:GetService('ReplicatedFirst'),
	ReplicatedStorage = game:GetService('ReplicatedStorage'),
	RunService = game:GetService('RunService'),
	SoundService = game:GetService('SoundService'),
	Workspace = game:GetService('Workspace')
}, {
    __index = function(t, serviceName)
        local success, service = pcall(function()
            return game:GetService(serviceName)
        end)

        if not success then
            error(('Cannot find service %q: %s'):format(serviceName, service))
        end

        t[serviceName] = service

        return service
    end
})
