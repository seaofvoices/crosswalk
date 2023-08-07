local FunctionMock = require('./FunctionMock')
export type FunctionMock = FunctionMock.FunctionMock
local PlayerMock = require('./PlayerMock')
local RemoteEventMock = require('./RemoteEventMock')
local RemoteFunctionMock = require('./RemoteFunctionMock')

return {
    Function = FunctionMock,
    Player = PlayerMock,
    RemoteEvent = RemoteEventMock,
    RemoteFunction = RemoteFunctionMock,
}
