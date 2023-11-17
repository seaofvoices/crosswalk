export type Reporter = {
    assert: (self: Reporter, condition: boolean?, message: string, ...any) -> (),
    error: (self: Reporter, message: string, ...any) -> (),
    warn: (self: Reporter, message: string, ...any) -> (),
    info: (self: Reporter, message: string, ...any) -> (),
    debug: (self: Reporter, message: string, ...any) -> (),
}

type Private = {
    _onError: (string) -> ()?,
    _onWarn: (string) -> ()?,
    _onInfo: (string) -> ()?,
    _onDebug: (string) -> ()?,
}

export type LogLevel = 'warn' | 'error' | 'info' | 'debug'

type NewReporterOptions = {
    onError: (string) -> ()?,
    onWarn: (string) -> ()?,
    onInfo: (string) -> ()?,
    onDebug: (string) -> ()?,
}
type ReporterStatic = Reporter & Private & {
    new: (NewReporterOptions) -> Reporter,
    errorOnly: () -> Reporter,
    default: () -> Reporter,
    newInfo: () -> Reporter,
    newDebug: () -> Reporter,
    fromLogLevel: (LogLevel) -> Reporter,
}

local Reporter: ReporterStatic = {} :: any
local ReporterMetatable = {
    __index = Reporter,
}

local function getMessage(message: string, ...: any): string
    if select('#', ...) == 0 then
        return message
    end
    return message:format(...)
end

function Reporter:assert(condition: boolean?, message: string, ...)
    local self = self :: Reporter & Private
    if not condition and self._onError then
        local message = getMessage(message, ...)
        self._onError(message)
    end
end

function Reporter:error(message: string, ...)
    local self = self :: Reporter & Private
    if self._onError then
        local message = getMessage(message, ...)
        self._onError(message)
    end
end

function Reporter:warn(message: string, ...)
    local self = self :: Reporter & Private
    if self._onWarn then
        local message = getMessage(message, ...)
        self._onWarn(message)
    end
end

function Reporter:info(message: string, ...)
    local self = self :: Reporter & Private
    if self._onInfo then
        local message = getMessage(message, ...)
        self._onInfo(message)
    end
end

function Reporter:debug(message: string, ...)
    local self = self :: Reporter & Private
    if self._onDebug then
        local message = getMessage(message, ...)
        self._onDebug(message)
    end
end

function Reporter.new(options: NewReporterOptions): Reporter
    return setmetatable({
        _onError = options.onError,
        _onWarn = options.onWarn,
        _onInfo = options.onInfo,
        _onDebug = options.onDebug,
    }, ReporterMetatable) :: any
end

local function logError(message)
    error('ERROR[crosswalk]: ' .. message)
end

local function logWarn(message)
    warn('WARN[crosswalk]: ' .. message)
end

local function logInfo(message)
    print('INFO[crosswalk]: ' .. message)
end

local function logDebug(message)
    print('DEBUG[crosswalk]: ' .. message)
end

function Reporter.default(): Reporter
    return Reporter.new({
        onError = logError,
        onWarn = logWarn,
        onInfo = nil,
        onDebug = nil,
    })
end

function Reporter.newInfo(): Reporter
    return Reporter.new({
        onError = logError,
        onWarn = logWarn,
        onInfo = logInfo,
        onDebug = nil,
    })
end

function Reporter.newDebug(): Reporter
    return Reporter.new({
        onError = logError,
        onWarn = logWarn,
        onInfo = logInfo,
        onDebug = logDebug,
    })
end

function Reporter.errorOnly(): Reporter
    return Reporter.new({
        onError = logError,
        onWarn = nil,
        onInfo = nil,
        onDebug = nil,
    })
end

function Reporter.fromLogLevel(level: LogLevel): Reporter
    if level == 'warn' then
        return Reporter.default()
    elseif level == 'error' then
        return Reporter.errorOnly()
    elseif level == 'info' then
        return Reporter.newInfo()
    elseif level == 'debug' then
        return Reporter.newDebug()
    else
        error('invalid value for `logError`: expected `error`, `warn`, `info` or `debug`')
    end
end

return Reporter
