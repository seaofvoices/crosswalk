local jestGlobals = require('@pkg/@jsdotlua/jest-globals')

local RemoteStorage = require('../RemoteStorage')

local expect = jestGlobals.expect
local it = jestGlobals.it
local beforeEach = jestGlobals.beforeEach
local afterEach = jestGlobals.afterEach
local describe = jestGlobals.describe

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
        expect(remote.ClassName).toEqual('RemoteEvent')
    end)

    it('parents the remote into the given parent', function()
        local remote = storage:createEvent('module', 'process')
        expect(remote.Parent).toBe(remoteParent)
        local children = remoteParent:GetChildren()
        expect(#children).toEqual(1)
        expect(children[1]).toBe(remote)
    end)

    it('generates a random remote name', function()
        local remote = storage:createEvent('module', 'process')
        expect(remote.Name).toEqual('remote-1')
    end)
end)

describe('createFunction', function()
    it('creates a RemoteFunction', function()
        local remote = storage:createFunction('module', 'process')
        expect(remote.ClassName).toEqual('RemoteFunction')
    end)

    it('parents the remote into the given parent', function()
        local remote = storage:createFunction('module', 'process')
        expect(remote.Parent).toBe(remoteParent)
        local children = remoteParent:GetChildren()
        expect(#children).toEqual(1)
        expect(children[1]).toBe(remote)
    end)

    it('generates a random remote name', function()
        local remote = storage:createFunction('module', 'process')
        expect(remote.Name).toEqual('remote-1')
    end)
end)

describe('createOrphanEvent', function()
    it('creates a RemoteEvent', function()
        local remote = storage:createOrphanEvent('name')
        expect(remote.ClassName).toEqual('RemoteEvent')
    end)

    it('parents the remote into the given parent', function()
        local remote = storage:createOrphanEvent('name')
        expect(remote.Parent).toBe(remoteParent)
        local children = remoteParent:GetChildren()
        expect(#children).toEqual(1)
        expect(children[1]).toBe(remote)
    end)

    it('sets the remote name', function()
        local name = 'remote name'
        local remote = storage:createOrphanEvent(name)
        expect(remote.Name).toEqual(name)
    end)
end)

describe('createOrphanFunction', function()
    it('creates a RemoteFunction', function()
        local remote = storage:createOrphanFunction('name')
        expect(remote.ClassName).toEqual('RemoteFunction')
    end)

    it('parents the remote into the given parent', function()
        local remote = storage:createOrphanFunction('name')
        expect(remote.Parent).toBe(remoteParent)
        local children = remoteParent:GetChildren()
        expect(#children).toEqual(1)
        expect(children[1]).toBe(remote)
    end)

    it('sets the remote name', function()
        local name = 'remote name'
        local remote = storage:createOrphanFunction(name)
        expect(remote.Name).toEqual(name)
    end)
end)

describe('getRemoteId', function()
    local moduleName = 'some module'
    local functionName = 'process'

    it('returns a remote created from createEvent', function()
        local remote = storage:createEvent(moduleName, functionName)
        local id = storage:getRemoteId(moduleName, functionName)
        expect(remote.Name).toEqual(id)
    end)

    it('returns a remote created from createFunction', function()
        local remote = storage:createFunction(moduleName, functionName)
        local id = storage:getRemoteId(moduleName, functionName)
        expect(remote.Name).toEqual(id)
    end)
end)
