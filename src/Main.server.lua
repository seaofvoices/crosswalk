local ServerStorage = game:GetService('ServerStorage')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local ServerLoader = require(ServerStorage:WaitForChild('ServerLoader'))

local function GetModules(folder)
	local filtered = {}

	for _, script in ipairs(folder:GetChildren()) do
		if script:IsA('ModuleScript') and not script.Name:match('.+%.spec$') then
			table.insert(filtered, script)
		end
	end

	return filtered
end

ServerLoader({
	ServerModules = GetModules(ServerStorage:WaitForChild('ServerModules')),
	ClientModules = GetModules(ReplicatedStorage:WaitForChild('ClientModules')),
	SharedModules = GetModules(ReplicatedStorage:WaitForChild('SharedModules')),
})
