local FunctionMock = require('./FunctionMock')
type FunctionMock = FunctionMock.FunctionMock
local EventMock = require('./EventMock')
type EventMock = EventMock.EventMock

export type RemoteEventMock = RemoteEvent & {
    OnClientEvent: EventMock,
    OnServerEvent: EventMock,
    mocks: {
        FireClient: FunctionMock,
        FireServer: FunctionMock,
    },
}

type RemoteEventMockStatic = RemoteEventMock & {
    new: () -> RemoteEventMock,
}

local RemoteEventMock: RemoteEventMockStatic = {
    ClassName = 'RemoteEvent',
} :: any
local RemoteEventMockMetatable = {
    __index = RemoteEventMock,
}

function RemoteEventMock:FireClient(...)
    local self = self :: RemoteEventMock
    return self.mocks.FireClient:call(...)
end

function RemoteEventMock:FireServer(...)
    local self = self :: RemoteEventMock
    return self.mocks.FireServer:call(...)
end

function RemoteEventMock:IsA(className: string)
    return className == 'RemoteEvent'
end

function RemoteEventMock.new(): RemoteEventMock
    return setmetatable({
        Name = 'RemoteEvent',
        OnClientEvent = EventMock.new(),
        OnServerEvent = EventMock.new(),
        mocks = {
            FireClient = FunctionMock.new(),
            FireServer = FunctionMock.new(),
        },
    }, RemoteEventMockMetatable) :: any
end

return RemoteEventMock
