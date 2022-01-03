return function()
    local Reporter = require(script.Parent.Reporter)

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

    for _, level in ipairs({ 'error', 'warn', 'info', 'debug' }) do
        describe(level, function()
            local configName = 'on' .. level:sub(1, 1):upper() .. level:sub(2)

            it(('calls `%s` if it is defined'):format(configName), function()
                reporter[level](reporter, FORMATTER, MESSAGE_ARG)
                expect(#events).to.equal(1)
                expect(events[1].level).to.equal(level)
                expect(events[1].message).to.equal(EXPECTED_MESSAGE)
            end)

            it(('does not call `%s` if it is not defined'):format(configName), function()
                reporter[level](reporter, FORMATTER, MESSAGE_ARG)
                expect(#events).to.equal(1)
                expect(events[1].level).to.equal(level)
                expect(events[1].message).to.equal(EXPECTED_MESSAGE)
            end)
        end)
    end

    describe('assert', function()
        it('calls `onError` if the condition is nil', function()
            reporter:assert(nil, FORMATTER, MESSAGE_ARG)
            expect(#events).to.equal(1)
            expect(events[1].level).to.equal('error')
            expect(events[1].message).to.equal(EXPECTED_MESSAGE)
        end)

        it('calls `onError` if the condition is false', function()
            reporter:assert(false, FORMATTER, MESSAGE_ARG)
            expect(#events).to.equal(1)
            expect(events[1].level).to.equal('error')
            expect(events[1].message).to.equal(EXPECTED_MESSAGE)
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
                expect(#events).to.equal(0)
            end)
        end
    end)
end
