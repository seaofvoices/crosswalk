local ServerRemotes = require('../../ServerLoader/ServerRemotes')
type ServerRemotes = ServerRemotes.ServerRemotes

local Mocks = require('./Mocks')

export type RemoteEventMock = {
    moduleName: string,
    name: string,
    func: any,
    security: string,
}
export type ServerRemotesMock = ServerRemotes & {
    events: { RemoteEventMock },
    functions: { RemoteEventMock },
    clearPlayer: Mocks.FunctionMock,
}
local function createServerRemotesMock(): ServerRemotesMock
    return {
        events = {},
        functions = {},
        addEventToServer = function(self, moduleName, name, func, security)
            table.insert(self.events, {
                moduleName = moduleName,
                name = name,
                func = func,
                security = security,
            })
        end,
        addFunctionToServer = function(self, moduleName, name, func, security)
            table.insert(self.functions, {
                moduleName = moduleName,
                name = name,
                func = func,
                security = security,
            })
        end,
        clearPlayer = Mocks.Function.new(),
    } :: any
end

return createServerRemotesMock
