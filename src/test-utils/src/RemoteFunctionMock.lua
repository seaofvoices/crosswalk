local FunctionMock = require('./FunctionMock')
type FunctionMock = FunctionMock.FunctionMock

export type RemoteFunctionMock = RemoteFunction & {
    OnClientEvent: ((...any) -> any)?,
    OnServerEvent: ((...any) -> any)?,
    mocks: {
        InvokeClient: FunctionMock,
        InvokeServer: FunctionMock,
    },
}

type RemoteFunctionMockStatic = RemoteFunctionMock & {
    new: () -> RemoteFunctionMock,
}

local RemoteFunctionMock: RemoteFunctionMockStatic = {
    ClassName = 'RemoteFunction',
} :: any
local RemoteFunctionMockMetatable = {
    __index = RemoteFunctionMock,
}

function RemoteFunctionMock:InvokeClient(...)
    local self = self :: RemoteFunctionMock
    return self.mocks.InvokeClient:call(...)
end

function RemoteFunctionMock:InvokeServer(...)
    local self = self :: RemoteFunctionMock
    return self.mocks.InvokeServer:call(...)
end

function RemoteFunctionMock:IsA(className: string)
    return className == 'RemoteFunction'
end

function RemoteFunctionMock.new(): RemoteFunctionMock
    return setmetatable({
        Name = 'RemoteFunction',
        OnClientInvoke = nil,
        OnServerInvoke = nil,
        mocks = {
            InvokeClient = FunctionMock.new(),
            InvokeServer = FunctionMock.new(),
        },
    }, RemoteFunctionMockMetatable) :: any
end

return RemoteFunctionMock
