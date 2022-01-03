local ReplicatedFirst = game:GetService('ReplicatedFirst')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')

_G.DEV = true

local TestEZ = require(ReplicatedStorage:WaitForChild('TestEZ'))

TestEZ.TestBootstrap:run({
    ReplicatedFirst:WaitForChild('ClientLoader'),
    ServerStorage:WaitForChild('ServerLoader'),
})
