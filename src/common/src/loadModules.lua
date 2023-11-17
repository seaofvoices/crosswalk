local loadNestedModules = require('./loadNestedModules')
local sortModuleByLevel = require('./sortModuleByLevel')
local Reporter = require('./Reporter')
type Reporter = Reporter.Reporter
local requireModule = require('./requireModule')
type CrosswalkModule = requireModule.CrosswalkModule
type LoadedModuleInfo = requireModule.LoadedModuleInfo

type LoadModuleOptions = {
    reporter: Reporter,
    verifyName: (moduleName: string, localModules: { [string]: any }) -> (),
    excludeModuleFilter: (ModuleScript) -> boolean,
    rootModulesMap: { [string]: any },
    baseModules: { [string]: any }?,
    localModulesMap: { [ModuleScript]: { [string]: any } },
    requireModule: <T...>(moduleScript: ModuleScript, T...) -> CrosswalkModule,
    useRecursiveMode: boolean,
    moduleKind: 'server' | 'shared' | 'client',
    onRootLoaded: (LoadedModuleInfo) -> (),
}

local function loadModules(moduleScripts: { ModuleScript }, options: LoadModuleOptions, ...: any)
    local localModulesMap = options.localModulesMap
    local rootModulesMap = options.rootModulesMap
    local baseModules = options.baseModules

    local loadedModules = {}

    for _, moduleScript in moduleScripts do
        if options.excludeModuleFilter(moduleScript) then
            options.reporter:debug('exclude module `%s`', moduleScript.Name)
            continue
        end
        local moduleName = moduleScript.Name
        options.reporter:debug('loading %s module `%s`', options.moduleKind, moduleName)

        options.verifyName(moduleName, rootModulesMap)

        local localModules = nil
        if options.useRecursiveMode then
            localModules = if baseModules == nil then {} else table.clone(baseModules)
            localModulesMap[moduleScript] = localModules
        else
            localModules = rootModulesMap
        end

        local module = options.requireModule(moduleScript, localModules, ...)

        local moduleInfo = {
            name = moduleName,
            moduleScript = moduleScript,
            module = module,
            orders = { 1 + #loadedModules },
        }
        options.onRootLoaded(moduleInfo)
        rootModulesMap[moduleName] = module

        table.insert(loadedModules, moduleInfo)
    end

    if options.useRecursiveMode then
        for i = 1, #loadedModules do
            local moduleInfo = loadedModules[i]
            local localModules = localModulesMap[moduleInfo.moduleScript]

            for name, content in options.rootModulesMap do
                if baseModules == nil or baseModules[name] == nil then
                    localModules[name] = content
                end
            end

            local nestedModules = loadNestedModules({
                module = moduleInfo.moduleScript,
                reporter = options.reporter,
                requireModule = options.requireModule,
                localModulesMap = localModulesMap,
                baseModules = baseModules,
                orders = moduleInfo.orders,
                verifyName = options.verifyName,
                excludeModuleFilter = options.excludeModuleFilter,
            }, ...)
            table.move(nestedModules, 1, #nestedModules, #loadedModules + 1, loadedModules)
        end
    end

    sortModuleByLevel(loadedModules)

    return loadedModules
end

return loadModules
