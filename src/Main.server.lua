local ServerStorage = game:GetService('ServerStorage')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local ServerLoader = require('./ServerLoader')

local function getModules(folder: Instance): { ModuleScript }
    local filtered = {}

    for _, script in folder:GetChildren() do
        if script:IsA('ModuleScript') and not script.Name:match('.+%.spec$') then
            table.insert(filtered, script)
        end
    end

    return filtered
end

local server = ServerLoader.new({
    serverModules = getModules(ServerStorage:WaitForChild('ServerModules')),
    clientModules = getModules(ReplicatedStorage:WaitForChild('ClientModules')),
    sharedModules = getModules(ReplicatedStorage:WaitForChild('SharedModules')),
    externalModules = {},
    logLevel = nil, -- can be 'error', 'warn', 'info' or 'debug' (default is 'warn')
    onSecondPlayerRequest = function(_player) end,
    onKeyError = function(_player, _moduleName, _functionName) end,
    onKeyMissing = function(_player, _moduleName, _functionName) end,
    onUnapprovedExecution = function(player, info)
        warn(
            ('Function %s.%s called by player `%s` (id:%d) was not approved'):format(
                info.moduleName,
                info.functionName,
                player.Name,
                player.UserId
            )
        )
    end,
    remoteCallMaxDelay = 2,
})
server:start()
