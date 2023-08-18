local createKey = require('./createKey')
local Map2D = require('./Map2D')
type Map2D<T, U, V> = Map2D.Map2D<T, U, V>

export type RemoteStorage = {
    createEvent: (self: RemoteStorage, moduleName: string, functionName: string) -> RemoteEvent,
    createFunction: (
        self: RemoteStorage,
        moduleName: string,
        functionName: string
    ) -> RemoteFunction,
    getRemoteId: (self: RemoteStorage, moduleName: string, functionName: string) -> string,
    createOrphanEvent: (self: RemoteStorage, remoteName: string) -> RemoteEvent,
    createOrphanFunction: (self: RemoteStorage, remoteName: string) -> RemoteFunction,
}

type Private = {
    _create: (
        self: RemoteStorage,
        className: 'RemoteEvent' | 'RemoteFunction',
        moduleName: string,
        functionName: string
    ) -> RemoteEvent | RemoteFunction,

    remoteParent: Instance,
    createRemoteId: () -> string,
    remoteNameToIdMap: Map2D<string, string, string>,
}
type RemoteStorageStatic = RemoteStorage & Private & {
    new: (remoteParent: Instance, createRemoteId: (() -> string)?) -> RemoteStorage,
}

local RemoteStorage: RemoteStorageStatic = {} :: any
local RemoteStorageMetatable = {
    __index = RemoteStorage,
}

function RemoteStorage.new(remoteParent, createRemoteId: (() -> string)?): RemoteStorage
    return setmetatable({
        remoteParent = remoteParent,
        createRemoteId = createRemoteId or createKey,
        remoteNameToIdMap = Map2D.new(),
    }, RemoteStorageMetatable) :: any
end

function RemoteStorage:createEvent(moduleName: string, functionName: string): RemoteEvent
    local self = self :: RemoteStorage & Private

    return self:_create('RemoteEvent', moduleName, functionName) :: RemoteEvent
end

function RemoteStorage:createFunction(moduleName: string, functionName: string): RemoteFunction
    local self = self :: RemoteStorage & Private

    return self:_create('RemoteFunction', moduleName, functionName) :: RemoteFunction
end

function RemoteStorage:getRemoteId(moduleName: string, functionName: string): string
    local self = self :: RemoteStorage & Private

    local id = self.remoteNameToIdMap:get(moduleName, functionName)

    if id ~= nil then
        return id
    else
        error('failed to obtain remote id')
    end
end

function RemoteStorage:createOrphanEvent(remoteName: string)
    local self = self :: RemoteStorage & Private

    local remote = Instance.new('RemoteEvent')
    remote.Name = remoteName
    remote.Parent = self.remoteParent
    return remote
end

function RemoteStorage:createOrphanFunction(remoteName: string)
    local self = self :: RemoteStorage & Private

    local remote = Instance.new('RemoteFunction')
    remote.Name = remoteName
    remote.Parent = self.remoteParent
    return remote
end

function RemoteStorage:_create(
    className: 'RemoteEvent' | 'RemoteFunction',
    moduleName: string,
    functionName: string
): RemoteEvent | RemoteFunction
    local self = self :: RemoteStorage & Private

    local id = self.createRemoteId()
    self.remoteNameToIdMap:insert(moduleName, functionName, id)

    local remote = Instance.new(className)
    remote.Name = id
    remote.Parent = self.remoteParent

    return remote :: any
end

return RemoteStorage
