return function()
    local RemoteStorage = require('./RemoteStorage')

    local storage = nil
    local remoteParent = nil

    beforeEach(function()
        local nextId = 1
        local function generateId()
            local id = 'remote-' .. tostring(nextId)
            nextId = nextId + 1
            return id
        end
        remoteParent = Instance.new('Folder')
        storage = RemoteStorage.new(remoteParent, generateId)
    end)

    afterEach(function()
        remoteParent:Destroy()
        remoteParent = nil :: any
    end)

    describe('createEvent', function()
        it('creates a RemoteEvent', function()
            local remote = storage:createEvent('module', 'process')
            expect(remote.ClassName).to.equal('RemoteEvent')
        end)

        it('parents the remote into the given parent', function()
            local remote = storage:createEvent('module', 'process')
            expect(remote.Parent).to.equal(remoteParent)
            local children = remoteParent:GetChildren()
            expect(#children).to.equal(1)
            expect(children[1]).to.equal(remote)
        end)

        it('generates a random remote name', function()
            local remote = storage:createEvent('module', 'process')
            expect(remote.Name).to.equal('remote-1')
        end)
    end)

    describe('createFunction', function()
        it('creates a RemoteFunction', function()
            local remote = storage:createFunction('module', 'process')
            expect(remote.ClassName).to.equal('RemoteFunction')
        end)

        it('parents the remote into the given parent', function()
            local remote = storage:createFunction('module', 'process')
            expect(remote.Parent).to.equal(remoteParent)
            local children = remoteParent:GetChildren()
            expect(#children).to.equal(1)
            expect(children[1]).to.equal(remote)
        end)

        it('generates a random remote name', function()
            local remote = storage:createFunction('module', 'process')
            expect(remote.Name).to.equal('remote-1')
        end)
    end)

    describe('createOrphanEvent', function()
        it('creates a RemoteEvent', function()
            local remote = storage:createOrphanEvent('name')
            expect(remote.ClassName).to.equal('RemoteEvent')
        end)

        it('parents the remote into the given parent', function()
            local remote = storage:createOrphanEvent('name')
            expect(remote.Parent).to.equal(remoteParent)
            local children = remoteParent:GetChildren()
            expect(#children).to.equal(1)
            expect(children[1]).to.equal(remote)
        end)

        it('sets the remote name', function()
            local name = 'remote name'
            local remote = storage:createOrphanEvent(name)
            expect(remote.Name).to.equal(name)
        end)
    end)

    describe('createOrphanFunction', function()
        it('creates a RemoteFunction', function()
            local remote = storage:createOrphanFunction('name')
            expect(remote.ClassName).to.equal('RemoteFunction')
        end)

        it('parents the remote into the given parent', function()
            local remote = storage:createOrphanFunction('name')
            expect(remote.Parent).to.equal(remoteParent)
            local children = remoteParent:GetChildren()
            expect(#children).to.equal(1)
            expect(children[1]).to.equal(remote)
        end)

        it('sets the remote name', function()
            local name = 'remote name'
            local remote = storage:createOrphanFunction(name)
            expect(remote.Name).to.equal(name)
        end)
    end)

    describe('getRemoteId', function()
        local moduleName = 'some module'
        local functionName = 'process'

        it('returns a remote created from createEvent', function()
            local remote = storage:createEvent(moduleName, functionName)
            local id = storage:getRemoteId(moduleName, functionName)
            expect(remote.Name).to.equal(id)
        end)

        it('returns a remote created from createFunction', function()
            local remote = storage:createFunction(moduleName, functionName)
            local id = storage:getRemoteId(moduleName, functionName)
            expect(remote.Name).to.equal(id)
        end)
    end)
end
