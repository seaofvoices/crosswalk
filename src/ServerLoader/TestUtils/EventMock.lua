local ConnectionMock = {}
local ConnectionMockMetatable = { __index = ConnectionMock }

function ConnectionMock:Disconnect()
    assert(self.signal, 'cannot disconnect signal twice')
    self.signal.connections[self.callback] = nil
    self.signal = nil
    self.callback = nil
end

local function newConnectionMock(signal, callback)
    return setmetatable({
        signal = signal,
        callback = callback,
    }, ConnectionMockMetatable)
end

local EventMock = {}
local EventMockMetatable = { __index = EventMock }

function EventMock:Connect(callback)
    self.connections[callback] = true
    return newConnectionMock(self, callback)
end

function EventMock:Fire(...)
    for callback in pairs(self.connections) do
        callback(...)
    end
end

local function new()
    return setmetatable({
        connections = {},
    }, EventMockMetatable)
end

return {
    new = new,
}
