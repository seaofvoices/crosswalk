type ModuleInfo = { module: any, orders: { number } }

local function sortByLevel(moduleA: ModuleInfo, moduleB: ModuleInfo): boolean
    local aLength = #moduleA.orders
    local bLength = #moduleB.orders
    if aLength == bLength then
        for position, order in moduleA.orders do
            if order == moduleB.orders[position] then
                continue
            end
            return order < moduleB.orders[position]
        end
        return false
    end
    return aLength < bLength
end

local function sortModuleByLevel(modules: { ModuleInfo }): { any }
    table.sort(modules, sortByLevel)

    local actualModules = {}

    for _, moduleData in modules do
        table.insert(actualModules, moduleData.module)
    end

    return actualModules
end

return sortModuleByLevel
