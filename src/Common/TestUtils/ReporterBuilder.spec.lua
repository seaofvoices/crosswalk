return function()
    local ReporterBuilder = require(script.Parent.ReporterBuilder)

    local MESSAGE = 'oof'

    for _, level in ipairs({ 'error', 'warn', 'info', 'debug' }) do
        it(('logs %s calls'):format(level), function()
            local reporter = ReporterBuilder.new():build()
            reporter[level](reporter, MESSAGE)

            expect(#reporter.events).to.equal(1)
            local event = reporter.events[1]
            expect(event.level).to.equal(level)
            expect(event.message).to.equal(MESSAGE)
        end)
    end
end
