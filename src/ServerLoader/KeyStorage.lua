local createKey = require('./createKey')
local Map2D = require('./Map2D')

local KeyStorage = {}
local KeyStorageMetatable = { __index = KeyStorage }

function KeyStorage:createKey(player, moduleName, functionName)
    local playerKeys = self.playerKeys[player]
    if playerKeys == nil then
        playerKeys = Map2D.new()
        self.playerKeys[player] = playerKeys
    end
    local key = self._createKey()
    playerKeys:insert(moduleName, functionName, key)
    return key
end

function KeyStorage:setNewKey(player, moduleName, functionName)
    local key = self._createKey()
    self.playerKeys[player]:insert(moduleName, functionName, key)
    self.sendKey(player, key, moduleName, functionName)
end

function KeyStorage:verifyKey(player, moduleName, functionName, key)
    local playerKeys = self.playerKeys[player]
    if playerKeys == nil then
        self.reporter:warn('No key set for player `%s`', player.Name)
        task.spawn(self.onKeyMissing, player, moduleName, functionName)
        return false
    end

    local currentKey = playerKeys:get(moduleName, functionName)

    if currentKey == nil then
        self.reporter:warn(
            'No key set for module `%s.%s` (player `%s`)',
            moduleName,
            functionName,
            player.Name
        )
        task.spawn(self.onKeyMissing, player, moduleName, functionName)
        return false
    end

    if currentKey == key then
        return true
    else
        task.spawn(self.onKeyError, player, moduleName, functionName)
        return false
    end
end

function KeyStorage:clearPlayer(player)
    self.playerKeys[player] = nil
end

local function new(options)
    return setmetatable({
        playerKeys = {},
        sendKey = options.sendKey,
        onKeyError = options.onKeyError,
        onKeyMissing = options.onKeyMissing,
        reporter = options.reporter,
        _createKey = options.createKey or createKey,
    }, KeyStorageMetatable)
end

return {
    new = new,
}
