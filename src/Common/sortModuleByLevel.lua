type ModuleInfo = { [string]: any, orders: { number } }

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

local function sortModuleByLevel(modules: { ModuleInfo })
    table.sort(modules, sortByLevel)
end

return sortModuleByLevel
