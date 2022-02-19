local TestUtils = script.Parent
local FunctionMock = require(TestUtils.FunctionMock)
local PlayerMock = require(TestUtils.PlayerMock)
local RemoteEventMock = require(TestUtils.RemoteEventMock)
local RemoteFunctionMock = require(TestUtils.RemoteFunctionMock)

return {
    Function = FunctionMock,
    Player = PlayerMock,
    RemoteEvent = RemoteEventMock,
    RemoteFunction = RemoteFunctionMock,
}
