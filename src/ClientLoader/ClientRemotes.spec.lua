return function()
    local ClientRemotes = require('./ClientRemotes')

    local Mocks = require('../Common/TestUtils/Mocks')

    type InstanceMock = Instance & {
        _children: { [string]: InstanceMock },
    }
    local remotesParent: InstanceMock

    local clientRemoteId = 'qwertty'
    local moduleName = 'SuperModule'
    local functionName = 'process'
    local getServerDataRemoteName = 'oof  '

    local function generateSetupData()
        return {
            Keys = {},
            WaitForKeyNames = {},
            Names = {
                [moduleName] = {
                    [functionName] = clientRemoteId,
                },
            },
            NameServerMap = {
                [moduleName] = false,
            },
        }
    end

    beforeEach(function()
        remotesParent = {
            _children = {
                Remotes = {
                    _children = {},
                    GetChildren = function(self)
                        return table.clone(self._children)
                    end,
                    WaitForChild = function(self, name)
                        return self._children[name]
                    end,
                },
            },
            WaitForChild = function(self, name)
                return self._children[name]
            end,
        } :: any
    end)

    describe('fireReadyRemote', function()
        it('fires a remote ending with a special sequence', function()
            local setupData = generateSetupData()

            local getServerDataRemote = Mocks.RemoteFunction.new()
            getServerDataRemote.Name = getServerDataRemoteName
            getServerDataRemote.mocks.InvokeServer:setMockImplementation(function()
                return setupData
            end)
            remotesParent._children.Remotes._children[getServerDataRemoteName] = getServerDataRemote

            local name = 'oof    '
            local remoteEventMock = Mocks.RemoteEvent.new()
            remoteEventMock.Name = name
            remotesParent._children.Remotes._children[name] = remoteEventMock
            local remotes = ClientRemotes.new({
                remotesParent = remotesParent,
            })

            remotes:listen()

            remotes:fireReadyRemote()
            remoteEventMock.mocks.FireServer:expectCalledOnce(expect)
        end)

        it('blocks until remote setup is completed', function()
            local setupData = generateSetupData()

            local getServerDataRemote = Mocks.RemoteFunction.new()
            getServerDataRemote.Name = getServerDataRemoteName
            getServerDataRemote.mocks.InvokeServer:setMockImplementation(function()
                task.wait()
                return setupData
            end)
            remotesParent._children.Remotes._children[getServerDataRemoteName] = getServerDataRemote

            local name = 'oof    '
            local remoteEventMock = Mocks.RemoteEvent.new()
            remoteEventMock.Name = name
            remotesParent._children.Remotes._children[name] = remoteEventMock

            local remotes = ClientRemotes.new({
                remotesParent = remotesParent,
            })

            remotes:listen()

            local fired = false
            task.spawn(function()
                remotes:fireReadyRemote()
                fired = true
            end)

            expect(fired).to.equal(false)
            task.wait()
            expect(fired).to.equal(true)
        end)
    end)

    describe('connectRemote', function()
        it('blocks until remote setup is completed', function()
            local setupData = generateSetupData()

            local getServerDataRemote = Mocks.RemoteFunction.new()
            getServerDataRemote.Name = getServerDataRemoteName
            getServerDataRemote.mocks.InvokeServer:setMockImplementation(function()
                task.wait()
                return setupData
            end)
            remotesParent._children.Remotes._children[getServerDataRemoteName] = getServerDataRemote
            local clientRemoteEvent = Mocks.RemoteEvent.new()
            remotesParent._children.Remotes._children[clientRemoteId] = clientRemoteEvent

            local remotes = ClientRemotes.new({
                remotesParent = remotesParent,
            })

            remotes:listen()

            local connected = false
            task.spawn(function()
                remotes:connectRemote(moduleName, functionName, function() end)
                connected = true
            end)

            expect(connected).to.equal(false)
            task.wait()
            expect(connected).to.equal(true)
        end)

        it('connects to `OnClientEvent` for RemoteEvent objects', function()
            local setupData = generateSetupData()

            local getServerDataRemote = Mocks.RemoteFunction.new()
            getServerDataRemote.Name = getServerDataRemoteName
            getServerDataRemote.mocks.InvokeServer:setMockImplementation(function()
                return setupData
            end)
            remotesParent._children.Remotes._children[getServerDataRemoteName] = getServerDataRemote
            local clientRemoteEvent = Mocks.RemoteEvent.new()
            remotesParent._children.Remotes._children[clientRemoteId] = clientRemoteEvent

            local remotes = ClientRemotes.new({
                remotesParent = remotesParent,
            })

            remotes:listen()

            local received = nil
            remotes:connectRemote(moduleName, functionName, function(...)
                received = table.pack(...)
            end)

            clientRemoteEvent.OnClientEvent:Fire('hello', false)

            expect(received).to.be.ok()
            expect(received.n).to.equal(2)
            expect(received[1]).to.equal('hello')
            expect(received[2]).to.equal(false)
        end)

        it('connects to `OnClientInvoke` for RemoteFunction objects', function()
            local setupData = generateSetupData()

            local getServerDataRemote = Mocks.RemoteFunction.new()
            getServerDataRemote.Name = getServerDataRemoteName
            getServerDataRemote.mocks.InvokeServer:setMockImplementation(function()
                return setupData
            end)
            remotesParent._children.Remotes._children[getServerDataRemoteName] =
                getServerDataRemote :: any
            local clientRemoteEvent = Mocks.RemoteFunction.new()
            remotesParent._children.Remotes._children[clientRemoteId] = clientRemoteEvent :: any

            local remotes = ClientRemotes.new({
                remotesParent = remotesParent,
            })

            remotes:listen()

            local received = nil
            remotes:connectRemote(moduleName, functionName, function(...)
                received = table.pack(...)
            end)

            clientRemoteEvent.OnClientInvoke('hello', false)

            expect(received).to.be.ok()
            expect(received.n).to.equal(2)
            expect(received[1]).to.equal('hello')
            expect(received[2]).to.equal(false)
        end)
    end)

    describe('server modules setup', function()
        local serverModuleName = 'Test'
        local serverFunctionName = 'process'
        local serverRemoteId = 'anyid'

        local returnSetupData = nil
        local keySenderRemote = nil

        beforeEach(function()
            returnSetupData = generateSetupData()

            local getServerDataRemote = Mocks.RemoteFunction.new()
            getServerDataRemote.Name = getServerDataRemoteName
            getServerDataRemote.mocks.InvokeServer:setMockImplementation(function()
                return returnSetupData
            end)
            remotesParent._children.Remotes._children[getServerDataRemoteName] = getServerDataRemote
            keySenderRemote = Mocks.RemoteEvent.new()
            local keySenderRemoteName = 'sendkeyremote   '
            keySenderRemote.Name = keySenderRemoteName
            remotesParent._children.Remotes._children[keySenderRemoteName] = keySenderRemote
        end)

        describe('RemoteEvent', function()
            local serverRemote = nil

            beforeEach(function()
                serverRemote = Mocks.RemoteEvent.new()
                remotesParent._children.Remotes._children[serverRemoteId] = serverRemote
                returnSetupData.Names[serverModuleName] = {
                    [serverFunctionName] = serverRemoteId,
                }
                returnSetupData.NameServerMap[serverModuleName] = true
            end)

            it('can call a server module function that does not use keys', function()
                returnSetupData.Keys = { [serverModuleName] = {} }

                local remotes = ClientRemotes.new({
                    remotesParent = remotesParent,
                })

                remotes:listen()

                local serverModules = remotes:getServerModules()

                local serverModuleWrapper = serverModules[serverModuleName]
                expect(serverModuleWrapper).to.be.ok()
                local serverModuleFunctionWrapper = serverModuleWrapper[serverFunctionName]
                expect(serverModuleFunctionWrapper).to.be.ok()

                local sentValue = 'hello'
                local received = serverModuleFunctionWrapper(sentValue)

                serverRemote.mocks.FireServer:expectCalledOnce(expect, sentValue)

                expect(received).to.equal(nil)
            end)

            it('can call a server module function that uses a constant key', function()
                local key = 'somekey'
                returnSetupData.Keys[serverModuleName] = {
                    [serverFunctionName] = key,
                }
                returnSetupData.WaitForKeyNames[serverModuleName] = {}

                local remotes = ClientRemotes.new({
                    remotesParent = remotesParent,
                })

                remotes:listen()

                local serverModules = remotes:getServerModules()

                local serverModuleWrapper = serverModules[serverModuleName]
                expect(serverModuleWrapper).to.be.ok()
                local serverModuleFunctionWrapper = serverModuleWrapper[serverFunctionName]
                expect(serverModuleFunctionWrapper).to.be.ok()

                local sentValue = 'hello'
                local received = serverModuleFunctionWrapper(sentValue)

                serverRemote.mocks.FireServer:expectCalledOnce(expect, key, sentValue)

                expect(received).to.equal(nil)
            end)

            it('can call a server module function that uses dynamic keys', function()
                local key = 'somekey'
                returnSetupData.Keys[serverModuleName] = {
                    [serverFunctionName] = key,
                }
                returnSetupData.WaitForKeyNames[serverModuleName] = {
                    [serverFunctionName] = true,
                }

                local remotes = ClientRemotes.new({
                    remotesParent = remotesParent,
                })

                remotes:listen()

                local serverModules = remotes:getServerModules()

                local serverModuleWrapper = serverModules[serverModuleName]
                expect(serverModuleWrapper).to.be.ok()
                local serverModuleFunctionWrapper = serverModuleWrapper[serverFunctionName]
                expect(serverModuleFunctionWrapper).to.be.ok()

                local sentValue = 'hello'

                local functionWrapperDone = false
                local received = nil

                task.spawn(function()
                    received = serverModuleFunctionWrapper(sentValue)
                    functionWrapperDone = true
                end)

                expect(functionWrapperDone).to.equal(false)

                keySenderRemote.OnClientEvent:Fire('newkey', serverModuleName, serverFunctionName)
                task.wait()

                expect(functionWrapperDone).to.equal(true)
                serverRemote.mocks.FireServer:expectCalledOnce(expect, key, sentValue)

                expect(received).to.equal(nil)
            end)
        end)

        describe('RemoteFunction', function()
            local serverRemote = nil

            beforeEach(function()
                serverRemote = Mocks.RemoteFunction.new()
                remotesParent._children.Remotes._children[serverRemoteId] = serverRemote
                returnSetupData.Names[serverModuleName] = {
                    [serverFunctionName] = serverRemoteId,
                }
                returnSetupData.NameServerMap[serverModuleName] = true
            end)

            it('can call a server module function that does not use keys', function()
                serverRemote.mocks.InvokeServer:returnSameValue('first', nil, nil, 4)

                returnSetupData.Keys = { [serverModuleName] = {} }

                local remotes = ClientRemotes.new({
                    remotesParent = remotesParent,
                })

                remotes:listen()

                local serverModules = remotes:getServerModules()

                local serverModuleWrapper = serverModules[serverModuleName]
                expect(serverModuleWrapper).to.be.ok()
                local serverModuleFunctionWrapper = serverModuleWrapper[serverFunctionName]
                expect(serverModuleFunctionWrapper).to.be.ok()

                local sentValue = 'hello'
                local received = table.pack(serverModuleFunctionWrapper(sentValue))

                serverRemote.mocks.InvokeServer:expectCalledOnce(expect, sentValue)

                expect(received).to.be.ok()
                expect(received.n).to.equal(4)
                expect(received[1]).to.equal('first')
                expect(received[2]).to.equal(nil)
                expect(received[3]).to.equal(nil)
                expect(received[4]).to.equal(4)
            end)

            it('can call a server module function that uses a constant key', function()
                serverRemote.mocks.InvokeServer:returnSameValue('first', nil, nil, 4)

                local key = 'somekey'
                returnSetupData.Keys[serverModuleName] = {
                    [serverFunctionName] = key,
                }
                returnSetupData.WaitForKeyNames[serverModuleName] = {}

                local remotes = ClientRemotes.new({
                    remotesParent = remotesParent,
                })

                remotes:listen()

                local serverModules = remotes:getServerModules()

                local serverModuleWrapper = serverModules[serverModuleName]
                expect(serverModuleWrapper).to.be.ok()
                local serverModuleFunctionWrapper = serverModuleWrapper[serverFunctionName]
                expect(serverModuleFunctionWrapper).to.be.ok()

                local sentValue = 'hello'
                local received = table.pack(serverModuleFunctionWrapper(sentValue))

                serverRemote.mocks.InvokeServer:expectCalledOnce(expect, key, sentValue)

                expect(received).to.be.ok()
                expect(received.n).to.equal(4)
                expect(received[1]).to.equal('first')
                expect(received[2]).to.equal(nil)
                expect(received[3]).to.equal(nil)
                expect(received[4]).to.equal(4)
            end)

            it('can call a server module function that uses dynamic keys', function()
                serverRemote.mocks.InvokeServer:returnSameValue('first', nil, nil, 4)

                local key = 'somekey'
                returnSetupData.Keys[serverModuleName] = {
                    [serverFunctionName] = key,
                }
                returnSetupData.WaitForKeyNames[serverModuleName] = {
                    [serverFunctionName] = true,
                }

                local remotes = ClientRemotes.new({
                    remotesParent = remotesParent,
                })

                remotes:listen()

                local serverModules = remotes:getServerModules()

                local serverModuleWrapper = serverModules[serverModuleName]
                expect(serverModuleWrapper).to.be.ok()
                local serverModuleFunctionWrapper = serverModuleWrapper[serverFunctionName]
                expect(serverModuleFunctionWrapper).to.be.ok()

                local sentValue = 'hello'

                local functionWrapperDone = false
                local received = nil

                task.spawn(function()
                    received = table.pack(serverModuleFunctionWrapper(sentValue))
                    functionWrapperDone = true
                end)

                expect(functionWrapperDone).to.equal(false)

                keySenderRemote.OnClientEvent:Fire('newkey', serverModuleName, serverFunctionName)
                task.wait()

                expect(functionWrapperDone).to.equal(true)
                serverRemote.mocks.InvokeServer:expectCalledOnce(expect, key, sentValue)

                expect(received).to.be.ok()
                expect(received.n).to.equal(4)
                expect(received[1]).to.equal('first')
                expect(received[2]).to.equal(nil)
                expect(received[3]).to.equal(nil)
                expect(received[4]).to.equal(4)
            end)
        end)
    end)
end
