local jestGlobals = require('@pkg/@jsdotlua/jest-globals')
local TestUtils = require('@pkg/crosswalk-test-utils')
local ReporterBuilder = TestUtils.ReporterBuilder

local expect = jestGlobals.expect
local it = jestGlobals.it
local beforeEach = jestGlobals.beforeEach
local describe = jestGlobals.describe

local KeyStorage = require('./KeyStorage')

local PLAYER_NAME = 'oof'

local calls = nil
local function getCallLogger(name)
    return function(...)
        table.insert(calls, {
            name = name,
            arguments = { ... },
        })
    end
end

local playerMock: Player = nil
local reporter
local storage
beforeEach(function()
    calls = {}
    playerMock = { Name = PLAYER_NAME } :: any
    reporter = ReporterBuilder.new():onlyWarn():build()

    local keyCounter = 1
    storage = KeyStorage.new({
        reporter = reporter,
        createKey = function()
            local key = tostring(keyCounter)
            keyCounter = keyCounter + 1
            return key
        end,
        sendKey = getCallLogger('sendKey'),
        onKeyError = getCallLogger('onKeyError'),
        onKeyMissing = getCallLogger('onKeyMissing'),
    })
end)

describe('createKey', function()
    it('returns the new key', function()
        local key = storage:createKey(playerMock, 'module', 'process')
        expect(key).toEqual('1')
    end)
end)

describe('verifyKey', function()
    it('returns true if the key matches', function()
        local key = storage:createKey(playerMock, 'module', 'processA')
        local verified = storage:verifyKey(playerMock, 'module', 'processA', key)

        expect(verified).toEqual(true)
    end)

    it('returns false if the key does not match', function()
        local key = storage:createKey(playerMock, 'module', 'processA')
        local verified = storage:verifyKey(playerMock, 'module', 'processA', key .. key)

        expect(verified).toEqual(false)
    end)

    it('calls `onKeyError` if the key does not match', function()
        local key = storage:createKey(playerMock, 'moduleName', 'process')
        storage:verifyKey(playerMock, 'moduleName', 'process', key .. key)

        expect(#calls).toEqual(1)
        expect(calls[1].name).toEqual('onKeyError')
        local arguments = calls[1].arguments
        expect(#arguments).toEqual(3)
        expect(arguments[1]).toEqual(playerMock)
        expect(arguments[2]).toEqual('moduleName')
        expect(arguments[3]).toEqual('process')
    end)

    describe('missing key', function()
        local CASES = {
            player = {
                createKey = nil,
                warning = ('No key set for player `%s`'):format(PLAYER_NAME),
                module = 'moduleName',
                name = 'process',
            },
            module = {
                createKey = { module = 'module-a', name = 'processA' },
                warning = ('No key set for module `module-b.processB` (player `%s`)'):format(
                    PLAYER_NAME
                ),
                module = 'module-b',
                name = 'processB',
            },
            ['function'] = {
                createKey = { module = 'moduleName', name = 'processA' },
                warning = ('No key set for module `moduleName.processB` (player `%s`)'):format(
                    PLAYER_NAME
                ),
                module = 'moduleName',
                name = 'processB',
            },
        }

        for caseName, info in pairs(CASES) do
            describe(('when the %s is not found'):format(caseName), function()
                it('does not verify', function()
                    if info.createKey then
                        storage:createKey(playerMock, info.createKey.module, info.createKey.name)
                    end
                    local verified =
                        storage:verifyKey(playerMock, info.module, info.name, 'any-key')

                    expect(verified).toEqual(false)
                end)

                it('calls `onKeyMissing`', function()
                    if info.createKey then
                        storage:createKey(playerMock, info.createKey.module, info.createKey.name)
                    end
                    storage:verifyKey(playerMock, info.module, info.name, 'any-key')

                    expect(#calls).toEqual(1)
                    expect(calls[1].name).toEqual('onKeyMissing')
                    local arguments = calls[1].arguments
                    expect(#arguments).toEqual(3)
                    expect(arguments[1]).toBe(playerMock)
                    expect(arguments[2]).toEqual(info.module)
                    expect(arguments[3]).toEqual(info.name)
                end)

                it('warns', function()
                    if info.createKey then
                        storage:createKey(playerMock, info.createKey.module, info.createKey.name)
                    end
                    storage:verifyKey(playerMock, info.module, info.name, 'any-key')

                    expect(#reporter.events).toEqual(1)
                    local event = reporter.events[1]
                    expect(event.message).toEqual(info.warning)
                    expect(event.level).toEqual('warn')
                end)
            end)
        end
    end)
end)

describe('setNewKey', function()
    it('stores the new key and can verify it', function()
        storage:createKey(playerMock, 'module', 'process')
        storage:setNewKey(playerMock, 'module', 'process')

        local verified = storage:verifyKey(playerMock, 'module', 'process', '2')

        expect(verified).toEqual(true)
    end)

    it('calls `sendKey`', function()
        local moduleName = 'Bank'
        local functionName = 'process'
        storage:createKey(playerMock, moduleName, functionName)
        storage:setNewKey(playerMock, moduleName, functionName)

        expect(#calls).toEqual(1)
        expect(calls[1].name).toEqual('sendKey')
        local arguments = calls[1].arguments
        expect(#arguments).toEqual(4)
        expect(arguments[1]).toBe(playerMock)
        expect(arguments[2]).toEqual('2')
        expect(arguments[3]).toEqual(moduleName)
        expect(arguments[4]).toEqual(functionName)
    end)
end)

describe('clearPlayer', function()
    it('removes the keys associated with the player', function()
        local moduleName = 'Bank'
        local functionName = 'process'
        local key = storage:createKey(playerMock, moduleName, functionName)
        expect(storage:verifyKey(playerMock, moduleName, functionName, key)).toEqual(true)

        storage:clearPlayer(playerMock)

        expect(storage:verifyKey(playerMock, moduleName, functionName, key)).toEqual(false)
    end)
end)
