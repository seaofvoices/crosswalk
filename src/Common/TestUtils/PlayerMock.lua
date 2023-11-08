local PlayerMock = {
    ClassName = 'Player',
}
local PlayerMockMetatable = {
    __index = PlayerMock,
    __tostring = function(playerMock)
        return playerMock.Name
    end,
}

local function new(): Player
    return setmetatable({
        Name = 'Player',
        UserId = 1234,
    }, PlayerMockMetatable) :: any
end

return {
    new = new,
}
