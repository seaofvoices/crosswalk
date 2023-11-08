local ReplicatedStorage = game:GetService('ReplicatedStorage')

local ClientLoader = require('./ClientLoader')

local clientLoader = ClientLoader.new({
    clientModules = ReplicatedStorage:WaitForChild('ClientModules'):GetChildren(),
    sharedModules = ReplicatedStorage:WaitForChild('SharedModules'):GetChildren(),
    externalModules = {},
    logLevel = nil, -- can be 'error', 'warn', 'info' or 'debug' (default is 'warn')
})
clientLoader:start()
