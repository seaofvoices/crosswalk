local function extractFunctionName(name)
    return name:match('^(.-)_')
end

return extractFunctionName
