local FunctionMock = require('./FunctionMock')
export type FunctionMock = FunctionMock.FunctionMock
local PlayerMock = require('./PlayerMock')
local RemoteEventMock = require('./RemoteEventMock')
export type RemoteEventMock = RemoteEventMock.RemoteEventMock
local RemoteFunctionMock = require('./RemoteFunctionMock')
export type RemoteFunctionMock = RemoteFunctionMock.RemoteFunctionMock

return {
    Function = FunctionMock,
    Player = PlayerMock,
    RemoteEvent = RemoteEventMock,
    RemoteFunction = RemoteFunctionMock,
}
