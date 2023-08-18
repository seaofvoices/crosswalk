local ClientRemotes = require('../../ClientLoader/ClientRemotes')
type ClientRemotes = ClientRemotes.ClientRemotes

local Mocks = require('./Mocks')

local function createClientRemotesMock(): ClientRemotes
    return {
        _remotes = {},
        _serverModules = {},
        getServerModules = function(self)
            return self._serverModules
        end,
        listen = Mocks.Function.new(),
        disconnect = Mocks.Function.new(),
        connectRemote = function(self, module, functionName, callback)
            if self._remotes[module] == nil then
                self._remotes[module] = {
                    [functionName] = callback,
                }
            else
                self._remotes[module][functionName] = callback
            end
        end,
        fireReadyRemote = Mocks.Function.new(),
    } :: any
end

return createClientRemotesMock
