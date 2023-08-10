local Reporter = require('./Reporter')
local requireModule = require('./requireModule')
type CrosswalkModule = requireModule.CrosswalkModule

local function loadNestedModule(
    moduleScript: ModuleScript,
    reporter: Reporter.Reporter,
    customRequireModule: <T...>(moduleScript: ModuleScript, T...) -> CrosswalkModule,
    localModulesMap: { [ModuleScript]: { [string]: any } },
    verifyName: (
        moduleName: string,
        localModules: { [string]: any }
    ) -> (),
    ...
): { CrosswalkModule }
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
            local subModuleName = subModule.Name
            reporter:debug('  > loading nested module `%s`', subModuleName)

            verifyName(subModuleName, parentModules)

            local subLocalModules = {}
            localModulesMap[subModule] = subLocalModules

            local module = customRequireModule(subModule, subLocalModules, ...)

            table.insert(loadedModules, module)
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

            local nestedModules = loadNestedModule(
                subModule,
                reporter,
                customRequireModule,
                localModulesMap,
                verifyName,
                ...
            )

            table.move(nestedModules, 1, #nestedModules, #loadedModules + 1, loadedModules)
        end
    end

    return loadedModules
end

return loadNestedModule
