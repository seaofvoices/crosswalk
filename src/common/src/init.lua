local defaultCustomModuleFilter = require('./defaultCustomModuleFilter')
local defaultExcludeModuleFilter = require('./defaultExcludeModuleFilter')
local extractFunctionName = require('./extractFunctionName')
local filterArray = require('./filterArray')
local loadModules = require('./loadModules')
local makeServices = require('./makeServices')
local RemoteInformation = require('./RemoteInformation')
local Reporter = require('./Reporter')
local requireModule = require('./requireModule')
local validateSharedModule = require('./validateSharedModule')

export type CrosswalkModule = requireModule.CrosswalkModule
export type LoadedModuleInfo = requireModule.LoadedModuleInfo
export type LogLevel = Reporter.LogLevel
export type RemoteInformation = RemoteInformation.RemoteInformation
export type Reporter = Reporter.Reporter
export type Services = makeServices.Services

return {
    defaultCustomModuleFilter = defaultCustomModuleFilter,
    defaultExcludeModuleFilter = defaultExcludeModuleFilter,
    extractFunctionName = extractFunctionName,
    filterArray = filterArray,
    loadModules = loadModules,
    makeServices = makeServices,
    requireModule = requireModule,
    validateSharedModule = validateSharedModule,
    Reporter = Reporter,
}
