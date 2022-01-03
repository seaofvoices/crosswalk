local Map2D = {}
local Map2DMetatable = { __index = Map2D }

function Map2D:get(firstKey, secondKey)
    local firstMap = self.content[firstKey]
    if firstMap == nil then
        return nil
    end
    return firstMap[secondKey]
end

function Map2D:insert(firstKey, secondKey, value)
    local firstMap = self.content[firstKey]
    if firstMap == nil then
        firstMap = {}
        self.content[firstKey] = firstMap
    end
    firstMap[secondKey] = value
end

function Map2D:remove(firstKey, secondKey)
    if secondKey == nil then
        self.content[firstKey] = nil
    elseif self.content[firstKey] then
        self.content[firstKey][secondKey] = nil
    end
end

local function new()
    return setmetatable({
        content = {},
    }, Map2DMetatable)
end

return {
    new = new,
}
