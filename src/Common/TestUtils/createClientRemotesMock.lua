local ClientRemotes = require('../../ClientLoader/ClientRemotes')
type ClientRemotes = ClientRemotes.ClientRemotes

local Mocks = require('./Mocks')

export type ClientRemotesMock = ClientRemotes & {
    remotes: { [string]: { [string]: () -> ()? } },
}

local function createClientRemotesMock(): ClientRemotesMock
    return {
        remotes = {},
        _serverModules = {},
        getServerModules = function(self)
            return self._serverModules
        end,
        listen = Mocks.Function.new(),
        disconnect = Mocks.Function.new(),
        connectRemote = function(
            self: ClientRemotesMock,
            module: string,
            functionName: string,
            callback
        )
            if self.remotes[module] == nil then
                self.remotes[module] = {
                    [functionName] = callback,
                }
            else
                self.remotes[module][functionName] = callback
            end
        end,
        fireReadyRemote = Mocks.Function.new(),
    } :: any
end

return createClientRemotesMock
