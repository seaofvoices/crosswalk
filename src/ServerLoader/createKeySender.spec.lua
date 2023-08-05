--!nocheck
return function()
    local createKeySender = require('./createKeySender')

    local function remoteMock(name)
        return {
            Name = name,
            FireClient = function(self, ...)
                table.insert(self._calls, {
                    name = 'FireClient',
                    arguments = { ... },
                })
            end,
            _calls = {},
        }
    end

    it('fires the client when calling the function', function()
        local storageMock = {
            createOrphanEvent = function(self, name)
                assert(self.remote == nil, 'should be called once')
                self.remote = remoteMock(name)
                return self.remote
            end,
        }
        local sendKey = createKeySender(storageMock)
        local playerMock = {}
        sendKey(playerMock, 'key', 'module', 'process')

        expect(#storageMock.remote._calls).to.equal(1)
        local call = storageMock.remote._calls[1]
        expect(call.name).to.equal('FireClient')
        expect(#call.arguments).to.equal(4)
        expect(call.arguments[1]).to.equal(playerMock)
        expect(call.arguments[2]).to.equal('key')
        expect(call.arguments[3]).to.equal('module')
        expect(call.arguments[4]).to.equal('process')
    end)
end
