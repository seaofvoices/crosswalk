--!nonstrict
local Reporter = {}
local ReporterMetatable = { __index = Reporter }

local function getMessage(message, ...)
    if select('#', ...) == 0 then
        return message
    end
    return message:format(...)
end

function Reporter:assert(condition, ...)
    if not condition and self.onError then
        local message = getMessage(...)
        self.onError(message)
    end
end

function Reporter:error(...)
    if self.onError then
        local message = getMessage(...)
        self.onError(message)
    end
end

function Reporter:warn(...)
    if self.onWarn then
        local message = getMessage(...)
        self.onWarn(message)
    end
end

function Reporter:info(...)
    if self.onInfo then
        local message = getMessage(...)
        self.onInfo(message)
    end
end

function Reporter:debug(...)
    if self.onInfo then
        local message = getMessage(...)
        self.onDebug(message)
    end
end

local function new(options)
    return setmetatable({
        onError = options.onError,
        onWarn = options.onWarn,
        onInfo = options.onInfo,
        onDebug = options.onDebug,
    }, ReporterMetatable)
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

local function default()
    return new({
        onError = logError,
        onWarn = logWarn,
        onInfo = nil,
        onDebug = nil,
    })
end

local function info()
    return new({
        onError = logError,
        onWarn = logWarn,
        onInfo = logInfo,
        onDebug = nil,
    })
end

local function debug()
    return new({
        onError = logError,
        onWarn = logWarn,
        onInfo = logInfo,
        onDebug = logDebug,
    })
end

local function errorOnly()
    return new({
        onError = logError,
        onWarn = nil,
        onInfo = nil,
        onDebug = nil,
    })
end

local function fromLogLevel(level)
    if level == 'warn' then
        return default()
    elseif level == 'error' then
        return errorOnly()
    elseif level == 'info' then
        return info()
    elseif level == 'debug' then
        return debug()
    else
        error('invalid value for `logError`: expected `error`, `warn`, `info` or `debug`')
    end
end

return {
    new = new,
    default = default,
    debug = debug,
    info = info,
    error = errorOnly,
    warn = default,
    fromLogLevel = fromLogLevel,
}
