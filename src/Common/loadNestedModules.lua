local Reporter = require('./Reporter')
local requireModule = require('./requireModule')
type CrosswalkModule = requireModule.CrosswalkModule

export type ModuleInfo = {
    module: any,
    orders: { number },
    moduleScript: ModuleScript,
    name: string,
}

local function loadNestedModule(
    options: {
        module: ModuleScript,
        reporter: Reporter.Reporter,
        requireModule: <T...>(moduleScript: ModuleScript, T...) -> CrosswalkModule,
        localModulesMap: { [ModuleScript]: { [string]: any } },
        baseModules: { [string]: any }?,
        orders: { number },
        verifyName: (moduleName: string, localModules: { [string]: any }) -> (),
        excludeModuleFilter: (ModuleScript) -> boolean,
    },
    ...
): { ModuleInfo }
    local moduleScript = options.module
    local reporter = options.reporter
    local localModulesMap = options.localModulesMap
    local baseModules = options.baseModules
    local excludeModuleFilter = options.excludeModuleFilter

    local children = moduleScript:GetChildren()

    if #children == 0 then
        return {}
    end

    local parentModules = localModulesMap[moduleScript]
    reporter:assert(
        parentModules ~= nil,
        'expected to find local modules of %s',
        moduleScript:GetFullName()
    )

    reporter:debug('loading nested modules of `%s`:', moduleScript.Name)

    local loadedModules = {}

    for _, subModule in children do
        if subModule:IsA('ModuleScript') then
            if excludeModuleFilter(subModule) then
                reporter:debug('  > skip module `%s`', subModule.Name)
                continue
            end

            local subModuleName = subModule.Name
            reporter:debug('  > loading nested module `%s`', subModuleName)

            options.verifyName(subModuleName, parentModules)

            local subLocalModules = if baseModules == nil then {} else table.clone(baseModules)
            localModulesMap[subModule] = subLocalModules

            local module = options.requireModule(subModule, subLocalModules, ...)

            local orders = table.clone(options.orders)
            table.insert(orders, 1 + #loadedModules)

            table.insert(loadedModules, {
                module = module,
                orders = orders,
                moduleScript = subModule,
                name = subModuleName,
            })
            parentModules[subModuleName] = module
        end
    end

    for i = 1, #loadedModules do
        local moduleInfo = loadedModules[i]
        local subModule = moduleInfo.moduleScript
        local localModules = localModulesMap[subModule]

        reporter:assert(
            localModules ~= nil,
            'expected to find modules of `%s`',
            subModule:GetFullName()
        )

        for name, module in parentModules do
            localModules[name] = module
        end

        local nestedModules = loadNestedModule({
            module = subModule,
            reporter = reporter,
            requireModule = options.requireModule,
            localModulesMap = localModulesMap,
            baseModules = baseModules,
            orders = moduleInfo.orders,
            verifyName = options.verifyName,
            excludeModuleFilter = excludeModuleFilter,
        }, ...)

        table.move(nestedModules, 1, #nestedModules, #loadedModules + 1, loadedModules)
    end

    return loadedModules
end

return loadNestedModule
