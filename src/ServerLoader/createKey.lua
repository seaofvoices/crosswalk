local HttpService = game:GetService('HttpService')

local function createKey(): string
    return HttpService:GenerateGUID()
end

return createKey
