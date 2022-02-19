local PlayerMock = {
    ClassName = 'Player',
}
local PlayerMockMetatable = {
    __index = PlayerMock,
    __tostring = function(playerMock)
        return playerMock.Name
    end,
}

local function new()
    return setmetatable({
        Name = 'Player',
    }, PlayerMockMetatable)
end

return {
    new = new,
}
