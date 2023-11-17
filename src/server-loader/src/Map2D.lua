export type Map2D<T, U, V> = {
    get: (self: Map2D<T, U, V>, T, U) -> V?,
    insert: (self: Map2D<T, U, V>, T, U, V) -> (),
    remove: (self: Map2D<T, U, V>, T, U) -> (),
    removeAll: (self: Map2D<T, U, V>, T) -> (),

    content: { [T]: { [U]: V } },
}
type Map2DStaticFns = {
    get: <T, U, V>(self: Map2D<T, U, V>, T, U) -> V?,
    insert: <T, U, V>(self: Map2D<T, U, V>, T, U, V) -> (),
    remove: <T, U, V>(self: Map2D<T, U, V>, T, U) -> (),
    removeAll: <T, U, V>(self: Map2D<T, U, V>, T) -> (),
}

type Private<T, U, V> = {}

type Map2DStatic = Map2DStaticFns & {
    new: <T, U, V>() -> Map2D<T, U, V>,
}

local Map2D: Map2DStatic = {} :: any
local Map2DMetatable = {
    __index = Map2D,
}

function Map2D.new<T, U, V>(): Map2D<T, U, V>
    return setmetatable({ content = {} }, Map2DMetatable) :: any
end

function Map2D:get<T, U, V>(firstKey: T, secondKey: U): V?
    local self: Map2D<T, U, V> & Private<T, U, V> = self :: any
    local firstMap = self.content[firstKey]
    if firstMap == nil then
        return nil
    end
    return firstMap[secondKey]
end

function Map2D:insert<T, U, V>(firstKey: T, secondKey: U, value: V)
    local self: Map2D<T, U, V> & Private<T, U, V> = self :: any
    local firstMap = self.content[firstKey]
    if firstMap == nil then
        firstMap = {}
        self.content[firstKey] = firstMap
    end
    firstMap[secondKey] = value
end

function Map2D:removeAll<T, U, V>(firstKey: T)
    local self: Map2D<T, U, V> & Private<T, U, V> = self :: any
    self.content[firstKey] = nil
end

function Map2D:remove<T, U, V>(firstKey: T, secondKey: U)
    local self: Map2D<T, U, V> & Private<T, U, V> = self :: any
    if self.content[firstKey] then
        self.content[firstKey][secondKey] = nil
    end
end

return Map2D
