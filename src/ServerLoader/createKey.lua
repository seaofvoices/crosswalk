local HttpService = game:GetService('HttpService')

local function createKey()
    return HttpService:GenerateGUID()
end

return createKey
