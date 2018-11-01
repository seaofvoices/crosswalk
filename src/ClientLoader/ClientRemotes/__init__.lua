local ClientRemotes = {}
local private = {}

private.GetFireRemoteEvent = require(script.GetFireRemoteEvent)(ClientRemotes, private)
private.GetFireRemoteFunction = require(script.GetFireRemoteFunction)(ClientRemotes, private)
private.YieldUntilNewKey = require(script.YieldUntilNewKey)(ClientRemotes, private)

ClientRemotes.ConnectRemote = require(script.ConnectRemote)(ClientRemotes, private)
ClientRemotes.Init = require(script.Init)(ClientRemotes, private)
ClientRemotes.Ready = require(script.Ready)(ClientRemotes, private)

return ClientRemotes
