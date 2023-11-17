export type EventMock = RBXScriptSignal & {
    Fire: (self: EventMock, ...any) -> (),
}

type Private = {
    connections: { [(...any) -> any]: true },
}
type EventMockStatic = EventMock & Private & {
    new: () -> EventMock,
}

local EventMock: EventMockStatic = {} :: any
local EventMockMetatable = {
    __index = EventMock,
}

type ConnectionMock = {
    _signal: (EventMock & Private)?,
    _callback: ((...any) -> any)?,
}
local ConnectionMock = {}
local ConnectionMockMetatable = { __index = ConnectionMock }

function ConnectionMock:Disconnect()
    local self = self :: ConnectionMock
    assert(self._signal and self._callback, 'cannot disconnect signal twice')
    self._signal.connections[self._callback] = nil
    self._signal = nil
    self._callback = nil
end

local function newConnectionMock(signal, callback: (...any) -> any): RBXScriptConnection
    return setmetatable({
        _signal = signal,
        _callback = callback,
    }, ConnectionMockMetatable) :: any
end

function EventMock:Connect(callback: (...any) -> any): RBXScriptConnection
    local self = self :: EventMock & Private
    self.connections[callback] = true
    return newConnectionMock(self, callback)
end

function EventMock:Fire(...: any)
    local self = self :: EventMock & Private
    for callback in pairs(self.connections) do
        callback(...)
    end
end

function EventMock.new(): EventMock
    return setmetatable({
        connections = {},
    }, EventMockMetatable) :: any
end

return EventMock
