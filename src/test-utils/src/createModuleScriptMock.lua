local FunctionMock = require('./FunctionMock')
type FunctionMock = FunctionMock.FunctionMock

export type ModuleScriptMock = ModuleScript & {
    GetChildren: FunctionMock,
}

local function createModuleScriptMock(name: string): ModuleScriptMock
    local getChildren = FunctionMock.new()
    getChildren:setMockImplementation(function()
        return {}
    end)
    return {
        Name = name,
        GetChildren = getChildren,
        GetFullName = FunctionMock.new():returnSameValue('game.' .. name),
        IsA = FunctionMock.new():setMockImplementation(function(_self, className: string)
            return className == 'ModuleScript'
        end),
    } :: any
end

return createModuleScriptMock
