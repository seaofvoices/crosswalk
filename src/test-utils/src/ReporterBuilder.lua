local Common = require('@pkg/crosswalk-common')
local Reporter = Common.Reporter

export type Reporter = Common.Reporter
type LogLevel = Common.LogLevel

type Event = {
    level: LogLevel,
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

function ReporterBuilder:build(): Reporter & HasEvents
    local self = self :: ReporterBuilder & Private
    local events = {}
    local function getLevelLogger(level: LogLevel)
        return function(message: string)
            table.insert(events, {
                level = level,
                message = message,
            })
        end
    end
    local reporter = Reporter.new({
        onError = if self.logError then getLevelLogger('error') else noop,
        onWarn = if self.logWarn then getLevelLogger('warn') else noop,
        onInfo = if self.logInfo then getLevelLogger('info') else noop,
        onDebug = if self.logDebug then getLevelLogger('debug') else noop,
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
