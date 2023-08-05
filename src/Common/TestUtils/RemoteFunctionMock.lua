local FunctionMock = require('./FunctionMock')

local RemoteFunctionMock = {
    ClassName = 'RemoteFunction',
}
local RemoteFunctionMockMetatable = { __index = RemoteFunctionMock }

function RemoteFunctionMock:InvokeClient(...)
    return self.mocks.InvokeClient:call(...)
end

function RemoteFunctionMock:InvokeServer(...)
    return self.mocks.InvokeServer:call(...)
end

function RemoteFunctionMock:IsA(className)
    return className == 'RemoteFunction'
end

local function new()
    return setmetatable({
        Name = 'RemoteFunction',
        OnClientInvoke = nil,
        OnServerInvoke = nil,
        mocks = {
            InvokeClient = FunctionMock.new(),
            InvokeServer = FunctionMock.new(),
        },
    }, RemoteFunctionMockMetatable)
end

return {
    new = new,
}
