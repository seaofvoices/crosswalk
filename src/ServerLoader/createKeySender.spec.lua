return function()
    local createKeySender = require('./createKeySender')

    local RemoteStorage = require('./RemoteStorage')
    type RemoteStorage = RemoteStorage.RemoteStorage
    local PlayerMock = require('../Common/TestUtils/PlayerMock')
    local RemoteEventMock = require('../Common/TestUtils/RemoteEventMock')
    type RemoteEventMock = RemoteEventMock.RemoteEventMock

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

        expect(storageMock.remote).to.be.ok()
        local remote = storageMock.remote :: RemoteEventMock

        expect(#remote.mocks.FireClient.calls).to.equal(1)
        local call = remote.mocks.FireClient.calls[1]
        expect(#call.arguments).to.equal(4)
        expect(call.arguments[1]).to.equal(playerMock)
        expect(call.arguments[2]).to.equal('key')
        expect(call.arguments[3]).to.equal('module')
        expect(call.arguments[4]).to.equal('process')
    end)
end
