local jestGlobals = require('@pkg/@jsdotlua/jest-globals')

local getSecurity = require('../getSecurity')

local expect = jestGlobals.expect
local it = jestGlobals.it

it('should return `None` if the given name contains `_danger`', function()
    expect(getSecurity('test_danger')).toEqual('None')
    expect(getSecurity('test_danger_event')).toEqual('None')
    expect(getSecurity('test_danger_func')).toEqual('None')
    expect(getSecurity('_danger')).toEqual('None')
end)

it('should return `Low` if the given name contains `_risky`', function()
    expect(getSecurity('test_risky')).toEqual('Low')
    expect(getSecurity('test_risky_event')).toEqual('Low')
    expect(getSecurity('test_risky_func')).toEqual('Low')
    expect(getSecurity('_risky')).toEqual('Low')
end)

it('should work with an empty string', function()
    expect(function()
        getSecurity('')
    end).never.toThrow()
end)

it('should return `High` when it does not match any other pattern', function()
    expect(getSecurity('')).toEqual('High')
    expect(getSecurity('function')).toEqual('High')
    expect(getSecurity('hey_test')).toEqual('High')
    expect(getSecurity('test_func')).toEqual('High')
    expect(getSecurity('danger_event')).toEqual('High')
    expect(getSecurity('risky_event')).toEqual('High')
end)
