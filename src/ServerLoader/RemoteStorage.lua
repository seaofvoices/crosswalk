local createKey = require('./createKey')
local Map2D = require('./Map2D')

local RemoteStorage = {}
local RemoteStorageMetatable = { __index = RemoteStorage }

function RemoteStorage:createEvent(moduleName, functionName)
    return self:_create('RemoteEvent', moduleName, functionName)
end

function RemoteStorage:createFunction(moduleName, functionName)
    return self:_create('RemoteFunction', moduleName, functionName)
end

function RemoteStorage:getRemoteId(moduleName, functionName)
    return self.remoteNameToIdMap:get(moduleName, functionName)
end

function RemoteStorage:createOrphanEvent(remoteName)
    local remote = Instance.new('RemoteEvent')
    remote.Name = remoteName
    remote.Parent = self.remoteParent
    return remote
end

function RemoteStorage:createOrphanFunction(remoteName)
    local remote = Instance.new('RemoteFunction')
    remote.Name = remoteName
    remote.Parent = self.remoteParent
    return remote
end

function RemoteStorage:_create(className, moduleName, functionName)
    local id = self.createRemoteId()
    self.remoteNameToIdMap:insert(moduleName, functionName, id)

    local remote = Instance.new(className)
    remote.Name = id
    remote.Parent = self.remoteParent

    return remote
end

local function new(remoteParent, createRemoteId)
    return setmetatable({
        remoteParent = remoteParent,
        createRemoteId = createRemoteId or createKey,
        remoteNameToIdMap = Map2D.new(),
    }, RemoteStorageMetatable)
end

return {
    new = new,
}
