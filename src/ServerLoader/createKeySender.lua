local createKey = require(script.Parent.createKey)

local function createKeySender(remoteStorage)
    local keySender = remoteStorage:createOrphanEvent(createKey() .. '   ')

    local function sendKey(player, key, moduleName, functionName)
        keySender:FireClient(player, key, moduleName, functionName)
    end

    return sendKey
end

return createKeySender
