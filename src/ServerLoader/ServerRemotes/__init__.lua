local ServerRemotes = {}
local private = {}

private.GetRemoteName = require(script.GetRemoteName)(ServerRemotes, private)
private.GetKey = require(script.GetKey)(ServerRemotes, private)
private.GetRemoteData = require(script.GetRemoteData)(ServerRemotes, private)
private.GetUniqueId = require(script.GetUniqueId)(ServerRemotes, private)
private.IsRemoteDataSent = require(script.IsRemoteDataSent)(ServerRemotes, private)
private.NewKey = require(script.NewKey)(ServerRemotes, private)
private.VerifyKey = require(script.VerifyKey)(ServerRemotes, private)

ServerRemotes.AddEventToClient = require(script.AddEventToClient)(ServerRemotes, private)
ServerRemotes.AddEventToServer = require(script.AddEventToServer)(ServerRemotes, private)
ServerRemotes.AddFunctionToClient = require(script.AddFunctionToClient)(ServerRemotes, private)
ServerRemotes.AddFunctionToServer = require(script.AddFunctionToServer)(ServerRemotes, private)
ServerRemotes.Init = require(script.Init)(ServerRemotes, private)
ServerRemotes.ServerReady = require(script.ServerReady)(ServerRemotes, private)
ServerRemotes.SetClientCallMaxDelay = require(script.SetClientCallMaxDelay)(ServerRemotes, private)
ServerRemotes.Subscribe = require(script.Subscribe)(ServerRemotes, private)

return ServerRemotes
