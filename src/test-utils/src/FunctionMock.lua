type Call = {
    argumentCount: number,
    arguments: { any },
}
type AnyFn = (...any) -> any
export type FunctionMock = {
    getFunctionValue: (self: FunctionMock) -> AnyFn,
    returnSameValue: (self: FunctionMock, ...any) -> AnyFn,
    setMockImplementation: (self: FunctionMock, callback: AnyFn) -> AnyFn,
    call: (self: FunctionMock, ...any) -> any,
    expectCalls: (self: FunctionMock, expect: any, expectedCalls: { Call }) -> (),
    expectNeverCalled: (self: FunctionMock, expect: any) -> (),
    expectCalledOnce: (self: FunctionMock, expect: any, ...any) -> (),

    calls: { Call },
}

type Private = {
    _innerCall: ((any) -> any)?,
}

type FunctionMockStatic = FunctionMock & Private & {
    new: () -> FunctionMock,
}

local FunctionMock: FunctionMockStatic = {} :: any
local FunctionMockMetatable = {
    __index = FunctionMock,
    __call = function(self, ...)
        return self:call(...)
    end,
}

function FunctionMock:getFunctionValue()
    local function logger(...)
        return self:call(...)
    end
    return logger
end

function FunctionMock:returnSameValue(...): AnyFn
    local self = self :: FunctionMock & Private
    local returnValues = table.pack(...)
    self._innerCall = function()
        return unpack(returnValues, 1, returnValues.n)
    end
    return self:getFunctionValue()
end

function FunctionMock:setMockImplementation(callback: AnyFn): AnyFn
    local self = self :: FunctionMock & Private
    self._innerCall = callback
    return self:getFunctionValue()
end

function FunctionMock:call(...)
    local self = self :: FunctionMock & Private
    table.insert(self.calls, {
        arguments = { ... },
        argumentCount = select('#', ...),
    })
    if self._innerCall then
        return self._innerCall(...)
    end
    return
end

function FunctionMock:expectCalls(expect: any, expectedCalls: { Call })
    expect(#self.calls).toEqual(#expectedCalls)
    for i = 1, #expectedCalls do
        local call = self.calls[i]
        expect(call.argumentCount).toEqual(expectedCalls[i].argumentCount)
        for j = 1, call.argumentCount do
            expect(call.arguments[j]).toEqual(expectedCalls[i].arguments[j])
        end
    end
end

function FunctionMock:expectNeverCalled(expect: any)
    expect(#self.calls).toEqual(0)
end

function FunctionMock:expectCalledOnce(expect: any, ...)
    expect(#self.calls).toEqual(1)
    local call = self.calls[1]

    expect(call.argumentCount).toEqual(select('#', ...))
    for i = 1, call.argumentCount do
        expect(call.arguments[i]).toEqual(select(i, ...))
    end
end

function FunctionMock.new(): FunctionMock
    return setmetatable({
        calls = {},
        _innerCall = nil,
    }, FunctionMockMetatable) :: any
end

return FunctionMock
