local Reporter = require('./Reporter')
local requireModule = require('./requireModule')
type CrosswalkModule = requireModule.CrosswalkModule

local function loadNestedModule(
    options: {
        module: ModuleScript,
        reporter: Reporter.Reporter,
        requireModule: <T...>(moduleScript: ModuleScript, T...) -> CrosswalkModule,
        localModulesMap: { [ModuleScript]: { [string]: any } },
        baseModules: { [string]: any }?,
        orders: { number },
        verifyName: (moduleName: string, localModules: { [string]: any }) -> (),
    },
    ...
): { { module: CrosswalkModule, orders: { number } } }
    local moduleScript = options.module
    local reporter = options.reporter
    local localModulesMap = options.localModulesMap
    local baseModules = options.baseModules

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
    local ordersMap = {}

    for siblingOrder, subModule in children do
        if subModule:IsA('ModuleScript') then
            local subModuleName = subModule.Name
            reporter:debug('  > loading nested module `%s`', subModuleName)

            options.verifyName(subModuleName, parentModules)

            local subLocalModules = if baseModules == nil then {} else table.clone(baseModules)
            localModulesMap[subModule] = subLocalModules

            local module = options.requireModule(subModule, subLocalModules, ...)

            local orders = table.clone(options.orders)
            table.insert(orders, siblingOrder)
            ordersMap[subModule] = orders

            table.insert(loadedModules, {
                module = module,
                orders = orders,
            })
            parentModules[subModuleName] = module
        end
    end

    for _, subModule in children do
        if subModule:IsA('ModuleScript') then
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
                orders = ordersMap[subModule],
                verifyName = options.verifyName,
            }, ...)

            table.move(nestedModules, 1, #nestedModules, #loadedModules + 1, loadedModules)
        end
    end

    return loadedModules
end

return loadNestedModule
