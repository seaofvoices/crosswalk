local FunctionMock = require(script.Parent.FunctionMock)

local RemoteFunctionMock = {
    ClassName = 'RemoteFunction',
}
local RemoteFunctionMockMetatable = { __index = RemoteFunctionMock }

function RemoteFunctionMock:InvokeClient(...)
    return self.mocks.InvokeClient:call(...)
end

function RemoteFunctionMock:InvokeServer(...)
    return self.mocks.FireServer:call(...)
end

local function new()
    return setmetatable({
        Name = 'RemoteEvent',
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
