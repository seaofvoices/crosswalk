local jestGlobals = require('@pkg/@jsdotlua/jest-globals')

local Reporter = require('./Reporter')

local expect = jestGlobals.expect
local it = jestGlobals.it
local beforeEach = jestGlobals.beforeEach
local describe = jestGlobals.describe

local FORMATTER = 'oof: %s'
local MESSAGE_ARG = 'reason'
local EXPECTED_MESSAGE = FORMATTER:format(MESSAGE_ARG)

local events = nil
local function getEventLogger(level)
    return function(message)
        table.insert(events, {
            level = level,
            message = message,
        })
    end
end

local reporter
beforeEach(function()
    events = {}
    reporter = Reporter.new({
        onError = getEventLogger('error'),
        onWarn = getEventLogger('warn'),
        onInfo = getEventLogger('info'),
        onDebug = getEventLogger('debug'),
    })
end)

local logLevels: { Reporter.LogLevel } = { 'error', 'warn', 'info', 'debug' }

for _, level in logLevels do
    describe(level, function()
        local configName = 'on' .. level:sub(1, 1):upper() .. level:sub(2)

        it(('calls `%s` if it is defined'):format(configName), function()
            reporter[level](reporter, FORMATTER, MESSAGE_ARG)
            expect(#events).toEqual(1)
            expect(events[1].level).toEqual(level)
            expect(events[1].message).toEqual(EXPECTED_MESSAGE)
        end)

        it(('does not call `%s` if it is not defined'):format(configName), function()
            reporter[level](reporter, FORMATTER, MESSAGE_ARG)
            expect(#events).toEqual(1)
            expect(events[1].level).toEqual(level)
            expect(events[1].message).toEqual(EXPECTED_MESSAGE)
        end)
    end)
end

describe('fromLogLevel', function()
    for _, level: Reporter.LogLevel in logLevels do
        it(('creates a reporter from `%s`'):format(level), function()
            local newReporter = Reporter.fromLogLevel(level)
            expect(newReporter).toBeDefined()
        end)
    end

    it('throws if not a valid reporter level', function()
        expect(function()
            Reporter.fromLogLevel('oof' :: any)
        end).toThrow(
            'invalid value for `logError`: expected `error`, `warn`, `info` or `debug`'
        )
    end)
end)

describe('assert', function()
    it('calls `onError` if the condition is nil', function()
        reporter:assert(nil, FORMATTER, MESSAGE_ARG)
        expect(#events).toEqual(1)
        expect(events[1].level).toEqual('error')
        expect(events[1].message).toEqual(EXPECTED_MESSAGE)
    end)

    it('calls `onError` if the condition is false', function()
        reporter:assert(false, FORMATTER, MESSAGE_ARG)
        expect(#events).toEqual(1)
        expect(events[1].level).toEqual('error')
        expect(events[1].message).toEqual(EXPECTED_MESSAGE)
    end)

    local TRUE_CASES = {
        ['true'] = true,
        ['zero'] = 0,
        ['a number'] = 33,
        ['an empty string'] = '',
        ['a string'] = 'abc',
        ['a table'] = {},
        ['a function'] = function() end,
    }

    for caseName, value in pairs(TRUE_CASES) do
        it(('does not call `onError` if the condition is %s'):format(caseName), function()
            reporter:assert(value, 'oof')
            expect(#events).toEqual(0)
        end)
    end
end)
