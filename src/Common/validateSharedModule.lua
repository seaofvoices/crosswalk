local SpecialFunctions = require('./SpecialFunctions')
local extractFunctionName = require('./extractFunctionName')

local EVENT_PATTERN = '_event$'
local FUNCTION_PATTERN = '_func$'

local function validateSharedModule(sharedModule, moduleName, reporter)
    for property, value in pairs(sharedModule) do
        if
            (property:match(EVENT_PATTERN) or property:match(FUNCTION_PATTERN))
            and typeof(value) == 'function'
        then
            reporter:warn(
                'shared module %q has a function %q that is meant to exist on client or server modules. '
                    .. 'It should probably be renamed to %q',
                moduleName,
                property,
                extractFunctionName(property)
            )
        end
    end

    for functionName, info in pairs(SpecialFunctions) do
        if sharedModule[functionName] then
            local destination = {}
            if info.server then
                table.insert(destination, 'a server module')
            end
            if info.client then
                table.insert(destination, 'a client module')
            end

            local messageEnd = ''

            if #destination == 1 then
                messageEnd = ' into ' .. destination[1]
            elseif #destination > 1 then
                local last = table.remove(destination)
                messageEnd = (' into %s or %s'):format(table.concat(destination, ', '), last)
            end

            reporter:warn(
                'shared module %q has a `%s` function defined that will not be called automatically. '
                    .. 'This function should be removed or the logic should be moved%s.',
                moduleName,
                functionName,
                messageEnd
            )
        end
    end
end

return validateSharedModule
