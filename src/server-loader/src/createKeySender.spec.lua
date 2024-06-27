local jestGlobals = require('@pkg/@jsdotlua/jest-globals')
local TestUtils = require('@pkg/crosswalk-test-utils')

local createKeySender = require('./createKeySender')

local RemoteStorage = require('./RemoteStorage')
type RemoteStorage = RemoteStorage.RemoteStorage

local expect = jestGlobals.expect
local it = jestGlobals.it

local PlayerMock = TestUtils.Mocks.Player
local RemoteEventMock = TestUtils.Mocks.RemoteEvent
type RemoteEventMock = TestUtils.RemoteEventMock

it('fires the client when calling the function', function()
    local storageMock: RemoteStorage & { remote: RemoteEventMock? } = {
        createOrphanEvent = function(self, name)
            assert(self.remote == nil, 'should be called once')
            self.remote = RemoteEventMock.new()
            self.remote.Name = name
            return self.remote
        end,
    } :: any
    local sendKey = createKeySender(storageMock)
    local playerMock = PlayerMock.new()
    sendKey(playerMock, 'key', 'module', 'process')

    expect(storageMock.remote).toBeDefined()
    local remote = storageMock.remote :: RemoteEventMock

    expect(#remote.mocks.FireClient.calls).toEqual(1)
    local call = remote.mocks.FireClient.calls[1]
    expect(#call.arguments).toEqual(4)
    expect(call.arguments[1]).toEqual(playerMock)
    expect(call.arguments[2]).toEqual('key')
    expect(call.arguments[3]).toEqual('module')
    expect(call.arguments[4]).toEqual('process')
end)
