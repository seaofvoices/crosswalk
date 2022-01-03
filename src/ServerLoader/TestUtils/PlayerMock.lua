local PlayerMock = {
    ClassName = 'Player',
}
local PlayerMockMetatable = { __index = PlayerMock }

local function new()
    return setmetatable({
        Name = 'Player',
    }, PlayerMockMetatable)
end

return {
    new = new,
}
