local FunctionMock = {}
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

function FunctionMock:returnSameValue(...)
    local returnValues = table.pack(...)
    self._innerCall = function()
        return unpack(returnValues, 1, returnValues.n)
    end
    return self:getFunctionValue()
end

function FunctionMock:setMockImplementation(callback)
    self._innerCall = callback
    return self:getFunctionValue()
end

function FunctionMock:call(...)
    table.insert(self.calls, {
        arguments = { ... },
        argumentCount = select('#', ...),
    })
    if self._innerCall then
        return self._innerCall(...)
    end
end

function FunctionMock:expectCalls(expect, expectedCalls)
    expect(#self.calls).to.equal(#expectedCalls)
    for i = 1, #expectedCalls do
        local call = self.calls[i]
        expect(call.argumentCount).to.equal(#expectedCalls[i])
        for j = 1, call.argumentCount do
            expect(call.arguments[j]).to.equal(expectedCalls[i][j])
        end
    end
end

function FunctionMock:expectNeverCalled(expect)
    expect(#self.calls).to.equal(0)
end

function FunctionMock:expectCalledOnce(expect, ...)
    expect(#self.calls).to.equal(1)
    local call = self.calls[1]

    expect(call.argumentCount).to.equal(select('#', ...))
    for i = 1, call.argumentCount do
        expect(call.arguments[i]).to.equal(select(i, ...))
    end
end

local function new()
    return setmetatable({
        calls = {},
        _innerCall = nil,
    }, FunctionMockMetatable)
end

return {
    new = new,
}
