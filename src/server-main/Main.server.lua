local ServerStorage = game:GetService('ServerStorage')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local ServerLoader = require('@pkg/crosswalk-server')

local server = ServerLoader.new({
    serverModules = ServerStorage:WaitForChild('ServerModules'):GetChildren(),
    clientModules = ReplicatedStorage:WaitForChild('ClientModules'):GetChildren(),
    sharedModules = ReplicatedStorage:WaitForChild('SharedModules'):GetChildren(),
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
