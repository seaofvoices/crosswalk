--!nocheck
return function()
    local ServerRemotes = require('./ServerRemotes')

    local KeyStorage = require('./KeyStorage')
    local RemoteStorage = require('./RemoteStorage')
    local Reporter = require('../Common/Reporter')
    local Mocks = require('../Common/TestUtils/Mocks')

    local calls = nil
    local function getCallLogger(name, list)
        return function(...)
            table.insert(list or calls, {
                name = name,
                arguments = { ... },
            })
        end
    end

    local function newServerRemotes(options)
        options = options or {}
        return ServerRemotes.new({
            isPlayerReady = options.isPlayerReady or function()
                return true
            end,
            remoteStorage = options.remoteStorage
                or RemoteStorage.new(options.remoteParent or Instance.new('Folder')),
            keyStorage = options.keyStorage or KeyStorage.new({
                sendKey = getCallLogger('sendKey'),
                onKeyError = getCallLogger('onKeyError'),
                onKeyMissing = getCallLogger('onKeyMissing'),
                reporter = options.reporter or Reporter.default(),
            }),
            playersService = options.playersService,
            reporter = options.reporter,
        })
    end

    local function newRemoteStorageMock()
        return {
            createEvent = function(self, moduleName, functionName)
                assert(self.event == nil, 'createEvent should be called once')
                self.event = Mocks.RemoteEvent.new()
                self.event.Name = ('%s.%s'):format(moduleName, functionName)
                return self.event
            end,
            createFunction = function(self, moduleName, functionName)
                assert(self.event == nil, 'createEvent should be called once')
                self.event = Mocks.RemoteFunction.new()
                self.event.Name = ('%s.%s'):format(moduleName, functionName)
                return self.event
            end,
        }
    end

    local playerMock = nil
    local otherPlayerMock = nil
    beforeEach(function()
        calls = {}
        playerMock = Mocks.Player.new()
        otherPlayerMock = Mocks.Player.new()
        otherPlayerMock.Name = 'OtherPlayer'
    end)

    local remoteToClientCases = {
        addEventToClient = {
            remoteClass = 'RemoteEvent',
            remoteMethod = 'FireClient',
            canThrow = false,
        },
        addFunctionToClient = {
            remoteClass = 'RemoteFunction',
            remoteMethod = 'InvokeClient',
            canThrow = true,
        },
    }
    for methodName, info in pairs(remoteToClientCases) do
        describe(methodName, function()
            local remoteStorageMock
            local firePlayer
            local fireAllPlayers
            local playerReady
            beforeEach(function()
                playerReady = {
                    [playerMock] = true,
                }
                remoteStorageMock = newRemoteStorageMock()
                local serverRemotes = newServerRemotes({
                    remoteStorage = remoteStorageMock,
                    isPlayerReady = function(player)
                        return playerReady[player] == true
                    end,
                    playersService = {
                        GetPlayers = function()
                            return { playerMock, otherPlayerMock }
                        end,
                    },
                })

                firePlayer, fireAllPlayers =
                    serverRemotes[methodName](serverRemotes, 'module', 'process')
            end)

            it('creates a new remote', function()
                local remote = remoteStorageMock.event
                expect(remote).to.be.ok()
                expect(remote.ClassName).to.equal(info.remoteClass)
                expect(remote.Name).to.equal('module.process')
            end)

            it('fires the remote to all players that are ready', function()
                fireAllPlayers(true, 'hello')

                local remote = remoteStorageMock.event
                remote.mocks[info.remoteMethod]:expectCalledOnce(expect, playerMock, true, 'hello')
            end)

            if _G.DEV then
                it('throws if the remote is fired without a player', function()
                    expect(function()
                        firePlayer(true)
                    end).to.throw(
                        'first argument must be a Player in function call `module.process` '
                            .. '(got `true` of type boolean)'
                    )
                end)
            else
                it('can fire the remote to one player', function()
                    firePlayer(playerMock, 'hello')

                    local remote = remoteStorageMock.event
                    remote.mocks[info.remoteMethod]:expectCalledOnce(expect, playerMock, 'hello')
                end)

                it('does not fire the remote if the player is not ready', function()
                    firePlayer(otherPlayerMock, 'hello')

                    local remote = remoteStorageMock.event
                    remote.mocks[info.remoteMethod]:expectNeverCalled(expect)
                end)

                it('can fire the remote with nil values between non-nil values', function()
                    firePlayer(playerMock, nil, nil, nil, nil, true)

                    local remote = remoteStorageMock.event
                    remote.mocks[info.remoteMethod]:expectCalledOnce(
                        expect,
                        playerMock,
                        nil,
                        nil,
                        nil,
                        nil,
                        true
                    )
                end)

                if info.canThrow then
                    it('catches any errors from calling the remote', function()
                        local remote = remoteStorageMock.event
                        remote[info.remoteMethod] = function()
                            error('an error happened')
                        end
                        expect(function()
                            firePlayer(playerMock)
                        end).never.to.throw()
                    end)

                    it('catches errors from one player when calling all players', function()
                        playerReady[otherPlayerMock] = true
                        local remote = remoteStorageMock.event
                        remote[info.remoteMethod] = function(_self, player)
                            if player == playerMock then
                                error('an error happened')
                            end
                            return 'value'
                        end
                        local allCalled = nil
                        expect(function()
                            allCalled = fireAllPlayers(playerMock)
                        end).never.to.throw()

                        expect(allCalled).to.equal(false)
                    end)
                end

                if info.remoteClass == 'RemoteFunction' then
                    it('collects player results', function()
                        local remote = remoteStorageMock.event
                        remote[info.remoteMethod] = function(_self, player)
                            return 'value', player
                        end
                        local allCalled = nil
                        local results = nil
                        expect(function()
                            allCalled, results = fireAllPlayers(playerMock)
                        end).never.to.throw()

                        expect(allCalled).to.equal(true)
                        expect(results).to.be.a('table')
                        expect(results[playerMock].n).to.equal(2)
                        expect(results[playerMock][1]).to.equal('value')
                        expect(results[playerMock][2]).to.equal(playerMock)
                    end)
                end
            end
        end)
    end

    local remoteToServerCases = {
        addEventToServer = {
            remoteClass = 'RemoteEvent',
            remoteMethod = 'FireClient',
            fireRemote = function(remote, ...)
                remote.OnServerEvent:Fire(...)
            end,
        },
        addFunctionToServer = {
            remoteClass = 'RemoteFunction',
            remoteMethod = 'InvokeClient',
            fireRemote = function(remote, ...)
                if remote.OnServerInvoke then
                    return remote.OnServerInvoke(...)
                end
                return
            end,
        },
    }

    for methodName, info in pairs(remoteToServerCases) do
        describe(methodName, function()
            local remoteStorageMock
            beforeEach(function()
                remoteStorageMock = newRemoteStorageMock()
            end)

            it('creates a new remote', function()
                local serverRemotes = newServerRemotes({
                    remoteStorage = remoteStorageMock,
                    isPlayerReady = function(player)
                        return player == playerMock
                    end,
                })
                serverRemotes[methodName](
                    serverRemotes,
                    'module',
                    'process',
                    function() end,
                    'High'
                )

                local remote = remoteStorageMock.event
                expect(remote).to.be.ok()
                expect(remote.ClassName).to.equal(info.remoteClass)
                expect(remote.Name).to.equal('module.process')
            end)

            it('errors if the security level is unknown', function()
                local serverRemotes = newServerRemotes({
                    remoteStorage = remoteStorageMock,
                    isPlayerReady = function(player)
                        return player == playerMock
                    end,
                })
                expect(function()
                    serverRemotes[methodName](
                        serverRemotes,
                        'module',
                        'process',
                        function() end,
                        'oof'
                    )
                end).to.throw(
                    'Unknown security level `oof`. Valid options are: High, Low or None'
                )
            end)

            local securityCases = {
                ['no security'] = {
                    security = 'None',
                    hasKey = false,
                },
                ['low security'] = {
                    security = 'Low',
                    hasKey = true,
                },
                ['high security'] = {
                    security = 'High',
                    hasKey = true,
                },
            }

            for describeSecurity, caseInfo in pairs(securityCases) do
                describe(describeSecurity, function()
                    local functionMock
                    local onUnapprovedExecution
                    local serverRemotes
                    beforeEach(function()
                        functionMock = Mocks.Function.new()
                        serverRemotes = newServerRemotes({
                            remoteStorage = remoteStorageMock,
                            isPlayerReady = function(player)
                                return player == playerMock
                            end,
                            keyStorage = {
                                verifyKey = function(_self, player)
                                    return player == playerMock
                                end,
                                setNewKey = function() end,
                            },
                        })
                        onUnapprovedExecution = Mocks.Function.new()
                        serverRemotes:setOnUnapprovedExecution(
                            onUnapprovedExecution:getFunctionValue()
                        )
                    end)

                    it('calls the given function', function()
                        serverRemotes[methodName](
                            serverRemotes,
                            'module',
                            'process',
                            functionMock:returnSameValue(true),
                            caseInfo.security
                        )
                        local remote = remoteStorageMock.event
                        if caseInfo.hasKey then
                            info.fireRemote(remote, playerMock, 'key', 'hello', 3)
                        else
                            info.fireRemote(remote, playerMock, 'hello', 3)
                        end
                        functionMock:expectCalledOnce(expect, playerMock, 'hello', 3)
                    end)

                    if caseInfo.hasKey then
                        it(
                            'triggers the `onUnapprovedExecution` callback if the key does not verify',
                            function()
                                serverRemotes[methodName](
                                    serverRemotes,
                                    'module',
                                    'process',
                                    functionMock:returnSameValue(false),
                                    caseInfo.security
                                )
                                local remote = remoteStorageMock.event
                                info.fireRemote(remote, playerMock, 'key', 'hello', 3)
                                onUnapprovedExecution:expectCalledOnce(
                                    expect,
                                    playerMock,
                                    'module',
                                    'process'
                                )
                            end
                        )
                    end
                end)
            end
        end)
    end

    describe('clearPlayer', function()
        it('clears the player information in KeyStorage', function()
            local clearPlayerMock = Mocks.Function.new()
            local keyStorageMock = {
                verifyKey = function()
                    return false
                end,
                setNewKey = function() end,
                clearPlayer = clearPlayerMock,
            }
            local serverRemotes = newServerRemotes({
                remoteStorage = newRemoteStorageMock(),
                isPlayerReady = function(player)
                    return player == playerMock
                end,
                keyStorage = keyStorageMock,
            })
            serverRemotes:clearPlayer(playerMock)
            clearPlayerMock:expectCalledOnce(expect, keyStorageMock, playerMock)
        end)
    end)
end
