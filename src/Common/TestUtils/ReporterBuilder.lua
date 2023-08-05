local Reporter = require('../Reporter')

local ReporterBuilder = {}
local ReporterBuilderMetatable = { __index = ReporterBuilder }

local function noop() end

function ReporterBuilder:build()
    local events = {}
    local function getLevelLogger(level)
        return function(message)
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
    })
    reporter.events = events
    return reporter
end

function ReporterBuilder:onlyWarn()
    self.logError = false
    self.logWarn = true
    self.logInfo = false
    self.logDebug = false
    return self
end

local function new()
    return setmetatable({
        logError = true,
        logWarn = true,
        logInfo = true,
        logDebug = true,
    }, ReporterBuilderMetatable)
end

return {
    new = new,
}
