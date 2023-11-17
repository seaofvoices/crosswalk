local createModuleLoaderTests = require('./createModuleLoaderTests')
local createModuleScriptMock = require('./createModuleScriptMock')
local Mocks = require('./Mocks')
local ReporterBuilder = require('./ReporterBuilder')
local RequireMock = require('./RequireMock')

export type ModuleScriptMock = createModuleScriptMock.ModuleScriptMock
export type Reporter = ReporterBuilder.Reporter
export type RequiredArgs = RequireMock.RequiredArgs
export type FunctionMock = Mocks.FunctionMock
export type RemoteEventMock = Mocks.RemoteEventMock
export type RemoteFunctionMock = Mocks.RemoteFunctionMock

return {
    createModuleLoaderTests = createModuleLoaderTests,
    createModuleScriptMock = createModuleScriptMock,
    Mocks = Mocks,
    ReporterBuilder = ReporterBuilder,
    RequireMock = RequireMock,
}
