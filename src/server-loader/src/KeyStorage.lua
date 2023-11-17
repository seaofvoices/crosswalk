local createKey = require('./createKey')
local Map2D = require('./Map2D')
type Map2D<T, U, V> = Map2D.Map2D<T, U, V>
local Reporter = require('../Common/Reporter')
type Reporter = Reporter.Reporter

export type KeyStorage = {
    createKey: (self: KeyStorage, Player, moduleName: string, functionName: string) -> string,
    setNewKey: (self: KeyStorage, Player, moduleName: string, functionName: string) -> (),
    verifyKey: (
        self: KeyStorage,
        Player,
        moduleName: string,
        functionName: string,
        key: string
    ) -> boolean,
    clearPlayer: (self: KeyStorage, player: Player) -> (),
}

type Private = {
    _playerKeys: { [Player]: Map2D<string, string, string> },
    _sendKey: (Player, key: string, moduleName: string, functionName: string) -> (),
    _onKeyError: (Player, moduleName: string, functionName: string) -> (),
    _onKeyMissing: (Player, moduleName: string, functionName: string) -> (),
    _reporter: Reporter,
    _createKey: () -> string,
}

type KeyStorageOptions = {
    sendKey: (Player, key: string, moduleName: string, functionName: string) -> (),
    onKeyError: (Player, moduleName: string, functionName: string) -> (),
    onKeyMissing: (Player, moduleName: string, functionName: string) -> (),
    reporter: Reporter,
    createKey: (() -> string)?,
}
type KeyStorageStatic = KeyStorage & Private & {
    new: (options: KeyStorageOptions) -> KeyStorage,
}

local KeyStorage: KeyStorageStatic = {} :: any
local KeyStorageMetatable = {
    __index = KeyStorage,
}

function KeyStorage.new(options: KeyStorageOptions): KeyStorage
    return setmetatable({
        _playerKeys = {},
        _sendKey = options.sendKey,
        _onKeyError = options.onKeyError,
        _onKeyMissing = options.onKeyMissing,
        _reporter = options.reporter,
        _createKey = options.createKey or createKey,
    }, KeyStorageMetatable) :: any
end

function KeyStorage:createKey(player: Player, moduleName: string, functionName: string): string
    local self = self :: KeyStorage & Private
    local playerKeys = self._playerKeys[player]
    if playerKeys == nil then
        playerKeys = Map2D.new()
        self._playerKeys[player] = playerKeys
    end
    local key = self._createKey()
    playerKeys:insert(moduleName, functionName, key)
    return key
end

function KeyStorage:setNewKey(player: Player, moduleName: string, functionName: string)
    local self = self :: KeyStorage & Private
    local key = self._createKey()
    self._playerKeys[player]:insert(moduleName, functionName, key)
    self._sendKey(player, key, moduleName, functionName)
end

function KeyStorage:verifyKey(
    player: Player,
    moduleName: string,
    functionName: string,
    key: string
): boolean
    local self = self :: KeyStorage & Private
    local playerKeys = self._playerKeys[player]
    if playerKeys == nil then
        self._reporter:warn('No key set for player `%s`', player.Name)
        task.spawn(self._onKeyMissing, player, moduleName, functionName)
        return false
    end

    local currentKey = playerKeys:get(moduleName, functionName)

    if currentKey == nil then
        self._reporter:warn(
            'No key set for module `%s.%s` (player `%s`)',
            moduleName,
            functionName,
            player.Name
        )
        task.spawn(self._onKeyMissing, player, moduleName, functionName)
        return false
    end

    if currentKey == key then
        return true
    else
        task.spawn(self._onKeyError, player, moduleName, functionName)
        return false
    end
end

function KeyStorage:clearPlayer(player: Player)
    local self = self :: KeyStorage & Private
    self._playerKeys[player] = nil
end

return KeyStorage
