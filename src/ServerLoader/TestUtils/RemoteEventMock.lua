local FunctionMock = require(script.Parent.FunctionMock)
local EventMock = require(script.Parent.EventMock)

local RemoteEventMock = {
    ClassName = 'RemoteEvent',
}
local RemoteEventMockMetatable = { __index = RemoteEventMock }

function RemoteEventMock:FireClient(...)
    return self.mocks.FireClient:call(...)
end

function RemoteEventMock:FireServer(...)
    return self.mocks.FireServer:call(...)
end

local function new()
    return setmetatable({
        Name = 'RemoteEvent',
        OnServerEvent = EventMock.new(),
        mocks = {
            FireClient = FunctionMock.new(),
            FireServer = FunctionMock.new(),
        },
    }, RemoteEventMockMetatable)
end

return {
    new = new,
}
