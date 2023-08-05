local ReplicatedStorage = game:GetService('ReplicatedStorage')

local ClientLoader = require('./ClientLoader')

local function getModules(folder: Instance): { ModuleScript }
    local filtered = {}

    for _, script in ipairs(folder:GetChildren()) do
        if script:IsA('ModuleScript') and not script.Name:match('.+%.spec$') then
            table.insert(filtered, script)
        end
    end

    return filtered
end

local clientLoader = ClientLoader.new({
    clientModules = getModules(ReplicatedStorage:WaitForChild('ClientModules')),
    sharedModules = getModules(ReplicatedStorage:WaitForChild('SharedModules')),
    externalModules = {},
    logLevel = nil, -- can be 'error', 'warn', 'info' or 'debug' (default is 'warn')
})
clientLoader:start()
