local ServerStorage = game:GetService('ServerStorage')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local ServerLoader = require(ServerStorage:WaitForChild('ServerLoader'))

ServerLoader{
	ServerFolder = ServerStorage:WaitForChild('ServerModules'),
	ClientFolder = ReplicatedStorage:WaitForChild('ClientModules'),
	SharedFolder = ReplicatedStorage:WaitForChild('SharedModules')
}
