return function()
    local KeyStorage = require('./KeyStorage')

    local ReporterBuilder = require('../Common/TestUtils/ReporterBuilder')

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

    local playerMock
    local reporter
    local storage
    beforeEach(function()
        calls = {}
        playerMock = { Name = PLAYER_NAME }
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
            expect(key).to.equal('1')
        end)
    end)

    describe('verifyKey', function()
        it('returns true if the key matches', function()
            local key = storage:createKey(playerMock, 'module', 'processA')
            local verified = storage:verifyKey(playerMock, 'module', 'processA', key)

            expect(verified).to.equal(true)
        end)

        it('returns false if the key does not match', function()
            local key = storage:createKey(playerMock, 'module', 'processA')
            local verified = storage:verifyKey(playerMock, 'module', 'processA', key .. key)

            expect(verified).to.equal(false)
        end)

        it('calls `onKeyError` if the key does not match', function()
            local key = storage:createKey(playerMock, 'moduleName', 'process')
            storage:verifyKey(playerMock, 'moduleName', 'process', key .. key)

            expect(#calls).to.equal(1)
            expect(calls[1].name).to.equal('onKeyError')
            local arguments = calls[1].arguments
            expect(#arguments).to.equal(3)
            expect(arguments[1]).to.equal(playerMock)
            expect(arguments[2]).to.equal('moduleName')
            expect(arguments[3]).to.equal('process')
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
                            storage:createKey(
                                playerMock,
                                info.createKey.module,
                                info.createKey.name
                            )
                        end
                        local verified =
                            storage:verifyKey(playerMock, info.module, info.name, 'any-key')

                        expect(verified).to.equal(false)
                    end)

                    it('calls `onKeyMissing`', function()
                        if info.createKey then
                            storage:createKey(
                                playerMock,
                                info.createKey.module,
                                info.createKey.name
                            )
                        end
                        storage:verifyKey(playerMock, info.module, info.name, 'any-key')

                        expect(#calls).to.equal(1)
                        expect(calls[1].name).to.equal('onKeyMissing')
                        local arguments = calls[1].arguments
                        expect(#arguments).to.equal(3)
                        expect(arguments[1]).to.equal(playerMock)
                        expect(arguments[2]).to.equal(info.module)
                        expect(arguments[3]).to.equal(info.name)
                    end)

                    it('warns', function()
                        if info.createKey then
                            storage:createKey(
                                playerMock,
                                info.createKey.module,
                                info.createKey.name
                            )
                        end
                        storage:verifyKey(playerMock, info.module, info.name, 'any-key')

                        expect(#reporter.events).to.equal(1)
                        local event = reporter.events[1]
                        expect(event.message).to.equal(info.warning)
                        expect(event.level).to.equal('warn')
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

            expect(verified).to.equal(true)
        end)

        it('calls `sendKey`', function()
            local moduleName = 'Bank'
            local functionName = 'process'
            storage:createKey(playerMock, moduleName, functionName)
            storage:setNewKey(playerMock, moduleName, functionName)

            expect(#calls).to.equal(1)
            expect(calls[1].name).to.equal('sendKey')
            local arguments = calls[1].arguments
            expect(#arguments).to.equal(4)
            expect(arguments[1]).to.equal(playerMock)
            expect(arguments[2]).to.equal('2')
            expect(arguments[3]).to.equal(moduleName)
            expect(arguments[4]).to.equal(functionName)
        end)
    end)

    describe('clearPlayer', function()
        it('removes the keys associated with the player', function()
            local moduleName = 'Bank'
            local functionName = 'process'
            local key = storage:createKey(playerMock, moduleName, functionName)
            expect(storage:verifyKey(playerMock, moduleName, functionName, key)).to.equal(true)

            storage:clearPlayer(playerMock)

            expect(storage:verifyKey(playerMock, moduleName, functionName, key)).to.equal(false)
        end)
    end)
end
