local ReplicatedFirst = game:GetService('ReplicatedFirst')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local ClientLoader = require(ReplicatedFirst:WaitForChild('ClientLoader'))

local function GetModules(folder)
	local filtered = {}

	for _, script in ipairs(folder:GetChildren()) do
		if script:IsA('ModuleScript') and not script.Name:match('.spec$') then
			table.insert(filtered, script)
		end
	end

	return filtered
end

ClientLoader({
	ClientModules = GetModules(ReplicatedStorage:WaitForChild('ClientModules')),
	SharedModules = GetModules(ReplicatedStorage:WaitForChild('SharedModules')),
})
