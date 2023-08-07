local Reporter = require('../Reporter')
export type Reporter = Reporter.Reporter

type Event = {
    level: Reporter.LogLevel,
    message: string,
}
type HasEvents = { events: { Event } }
export type ReporterBuilder = {
    build: (self: ReporterBuilder) -> Reporter & HasEvents,
    onlyWarn: (self: ReporterBuilder) -> ReporterBuilder,
}

type Private = {
    logError: boolean,
    logWarn: boolean,
    logInfo: boolean,
    logDebug: boolean,
}
type ReporterBuilderStatic = ReporterBuilder & Private & {
    new: () -> ReporterBuilder,
}

local ReporterBuilder: ReporterBuilderStatic = {} :: any
local ReporterBuilderMetatable = {
    __index = ReporterBuilder,
}

function ReporterBuilder.new(): ReporterBuilder
    return setmetatable({
        logError = true,
        logWarn = true,
        logInfo = true,
        logDebug = true,
    }, ReporterBuilderMetatable) :: any
end

local function noop() end

function ReporterBuilder:build(): Reporter.Reporter & HasEvents
    local self = self :: ReporterBuilder & Private
    local events = {}
    local function getLevelLogger(level: Reporter.LogLevel)
        return function(message: string)
            table.insert(events, {
                level = level,
                message = message,
            })
        end
    end
    local reporter = Reporter.new({
        onError = self.logError and getLevelLogger('error') or noop,
        onWarn = self.logWarn and getLevelLogger('warn') or noop,
        onInfo = self.logInfo and getLevelLogger('info') or noop,
        onDebug = self.logDebug and getLevelLogger('debug') or noop,
    }) :: any
    reporter.events = events
    return reporter
end

function ReporterBuilder:onlyWarn()
    local self = self :: ReporterBuilder & Private
    self.logError = false
    self.logWarn = true
    self.logInfo = false
    self.logDebug = false
    return self
end

return ReporterBuilder
