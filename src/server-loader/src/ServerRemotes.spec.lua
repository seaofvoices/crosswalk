return function()
    local ServerRemotes = require('./ServerRemotes')
    type ServerRemotes = ServerRemotes.ServerRemotes

    local KeyStorage = require('./KeyStorage')
    type KeyStorage = KeyStorage.KeyStorage
    local RemoteStorage = require('./RemoteStorage')
    type RemoteStorage = RemoteStorage.RemoteStorage

    local Common = require('@pkg/crosswalk-common')
    local Reporter = Common.Reporter
    local TestUtils = require('@pkg/crosswalk-test-utils')
    local Mocks = TestUtils.Mocks

    type RemoteEventMock = TestUtils.RemoteEventMock
    type RemoteFunctionMock = TestUtils.RemoteFunctionMock
    type Reporter = Common.Reporter

    local calls = nil
    type LoggerCall = {
        name: string,
        arguments: { [number]: any, n: number },
    }
    local function getCallLogger(name: string, list: { LoggerCall }?): (...any) -> ()
        return function(...)
            table.insert(list or calls, {
                name = name,
                arguments = table.pack(...),
            })
        end
    end

    type NewServerRemotesOptions = {
        isPlayerReady: ((Player) -> boolean)?,
        keyStorage: KeyStorage?,
        remoteStorage: RemoteStorage?,
        remoteParent: Instance?,
        playersService: Players?,
        reporter: Reporter?,
    }
    local function newServerRemotes(options: NewServerRemotesOptions?): ServerRemotes
        local options: NewServerRemotesOptions = options or {}
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

    type RemoteStorageMock = RemoteStorage & {
        event: RemoteFunctionMock?,
    }
    local function newRemoteStorageMock(): RemoteStorageMock
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
        } :: any
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
                    isPlayerReady = function(player: Player)
                        return playerReady[player] == true
                    end,
                    playersService = {
                        GetPlayers = function()
                            return { playerMock, otherPlayerMock }
                        end,
                    } :: any,
                })

                firePlayer, fireAllPlayers =
                    serverRemotes[methodName](serverRemotes, 'module', 'process')
            end)

            it('creates a new remote', function()
                expect(remoteStorageMock.event).to.be.ok()
                local remote = remoteStorageMock.event :: RemoteEventMock
                expect(remote.ClassName).to.equal(info.remoteClass)
                expect(remote.Name).to.equal('module.process')
            end)

            it('fires the remote to all players that are ready', function()
                fireAllPlayers(true, 'hello')

                expect(remoteStorageMock.event).to.be.ok()
                local remote = remoteStorageMock.event :: RemoteEventMock
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

                    expect(remoteStorageMock.event).to.be.ok()
                    local remote = remoteStorageMock.event :: RemoteEventMock
                    remote.mocks[info.remoteMethod]:expectCalledOnce(expect, playerMock, 'hello')
                end)

                it('does not fire the remote if the player is not ready', function()
                    firePlayer(otherPlayerMock, 'hello')

                    expect(remoteStorageMock.event).to.be.ok()
                    local remote = remoteStorageMock.event :: RemoteEventMock
                    remote.mocks[info.remoteMethod]:expectNeverCalled(expect)
                end)

                it('can fire the remote with nil values between non-nil values', function()
                    firePlayer(playerMock, nil, nil, nil, nil, true)

                    expect(remoteStorageMock.event).to.be.ok()
                    local remote = remoteStorageMock.event :: RemoteEventMock
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
                        expect(remoteStorageMock.event).to.be.ok()
                        local remote = remoteStorageMock.event :: RemoteEventMock;
                        (remote :: any)[info.remoteMethod] = function()
                            error('an error happened')
                        end
                        expect(function()
                            firePlayer(playerMock)
                        end).never.to.throw()
                    end)

                    it('catches errors from one player when calling all players', function()
                        playerReady[otherPlayerMock] = true
                        expect(remoteStorageMock.event).to.be.ok()
                        local remote = remoteStorageMock.event :: RemoteEventMock;
                        (remote :: any)[info.remoteMethod] = function(_self, player: Player)
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
                        expect(remoteStorageMock.event).to.be.ok()
                        local remote = remoteStorageMock.event :: RemoteEventMock;
                        (remote :: any)[info.remoteMethod] = function(_self, player: Player)
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

    type RemoteToServerCase = {
        remoteClass: 'RemoteEvent' | 'RemoteFunction',
        remoteMethod: 'FireClient' | 'InvokeClient',
        fireRemote: (...any) -> (),
    }
    local remoteToServerCases: { [string]: RemoteToServerCase } = {
        addEventToServer = {
            remoteClass = 'RemoteEvent',
            remoteMethod = 'FireClient',
            fireRemote = function(remote, ...: any)
                remote.OnServerEvent:Fire(...)
            end,
        },
        addFunctionToServer = {
            remoteClass = 'RemoteFunction',
            remoteMethod = 'InvokeClient',
            fireRemote = function(remote, ...: any)
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

                expect(remoteStorageMock.event).to.be.ok()
                local remote = remoteStorageMock.event :: RemoteEventMock
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
                            isPlayerReady = function(player: Player)
                                return player == playerMock
                            end,
                            keyStorage = {
                                verifyKey = function(_self, player: Player)
                                    return player == playerMock
                                end,
                                setNewKey = function() end,
                            } :: any,
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
            } :: any
            local serverRemotes = newServerRemotes({
                remoteStorage = newRemoteStorageMock(),
                isPlayerReady = function(player: Player)
                    return player == playerMock
                end,
                keyStorage = keyStorageMock,
            })
            serverRemotes:clearPlayer(playerMock)
            clearPlayerMock:expectCalledOnce(expect, keyStorageMock, playerMock)
        end)
    end)
end
