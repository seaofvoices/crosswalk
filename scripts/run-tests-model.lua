local ReplicatedStorage = game:GetService('ReplicatedStorage')

local TestEZ = require(ReplicatedStorage:WaitForChild('TestEZ'))

TestEZ.TestBootstrap:run({
    ReplicatedStorage:WaitForChild('Model'),
}, TestEZ.Reporters.TextReporterQuiet)
