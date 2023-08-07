local createKey = require('./createKey')
local RemoteStorage = require('./RemoteStorage')
type RemoteStorage = RemoteStorage.RemoteStorage

type KeySender = (
    player: Player,
    key: string,
    moduleName: string,
    functionName: string
) -> ()

local function createKeySender(remoteStorage: RemoteStorage): KeySender
    local keySender = remoteStorage:createOrphanEvent(createKey() .. '   ')

    local function sendKey(player: Player, key: string, moduleName: string, functionName: string)
        keySender:FireClient(player, key, moduleName, functionName)
    end

    return sendKey
end

return createKeySender
