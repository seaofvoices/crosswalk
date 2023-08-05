local PATH_SEPARATOR = '/'
local function trimEndSeparator(path: string): string
    return if string.sub(path, -1, -1) == PATH_SEPARATOR then string.sub(path, 1, -1) else path
end

local function join(path: string, otherPath: string, ...: string)
    local argCount = select('#', ...)
    if argCount == 0 then
        return if string.sub(path, -1, -1) == PATH_SEPARATOR
            then path .. otherPath
            else path .. '/' .. otherPath
    else
        local components = { trimEndSeparator(path), trimEndSeparator(otherPath) }
        for i = 1, argCount do
            table.insert(components, trimEndSeparator(select(i, ...)))
        end
        return table.concat(components, PATH_SEPARATOR)
    end
end

local function fileName(path: string): string
    local components = string.split(path, PATH_SEPARATOR)
    local name = components[#components]
    if name == nil then
        error('unable to get file name from path ' .. path)
    end
    return name
end

return {
    join = join,
    fileName = fileName,
}
