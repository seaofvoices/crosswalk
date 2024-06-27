local jestGlobals = require('@pkg/@jsdotlua/jest-globals')

local ReporterBuilder = require('./ReporterBuilder')

local expect = jestGlobals.expect
local it = jestGlobals.it

local MESSAGE = 'oof'

for _, level in ipairs({ 'error', 'warn', 'info', 'debug' }) do
    it(('logs %s calls'):format(level), function()
        local reporter = ReporterBuilder.new():build();
        (reporter :: any)[level](reporter, MESSAGE)

        expect(#reporter.events).toEqual(1)
        local event = reporter.events[1]
        expect(event.level).toEqual(level)
        expect(event.message).toEqual(MESSAGE)
    end)
end
