local function extractFunctionName(name: string): string
    return name:match('^(.-)_') or name
end

return extractFunctionName
