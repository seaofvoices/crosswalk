local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')

_G.DEV = true

local TestEZ = require(ReplicatedStorage:WaitForChild('TestEZ'))

TestEZ.TestBootstrap:run({
    ReplicatedStorage:WaitForChild('ClientLoader'),
    ServerStorage:WaitForChild('ServerLoader'),
})
