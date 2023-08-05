local FunctionMock = require('./FunctionMock')
local EventMock = require('./EventMock')

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

function RemoteEventMock:IsA(className)
    return className == 'RemoteEvent'
end

local function new()
    return setmetatable({
        Name = 'RemoteEvent',
        OnClientEvent = EventMock.new(),
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
