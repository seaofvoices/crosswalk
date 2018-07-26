local ReplicatedFirst = game:GetService('ReplicatedFirst')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local ClientLoader = require(ReplicatedFirst:WaitForChild('ClientLoader'))

ClientLoader{
	ClientFolder = ReplicatedStorage:WaitForChild('ClientModules'),
	SharedFolder = ReplicatedStorage:WaitForChild('SharedModules')
}
