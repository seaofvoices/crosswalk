local function defaultCustomModuleFilter(moduleScript: ModuleScript): boolean
    return moduleScript.Name:match('Class$') ~= nil
end

return defaultCustomModuleFilter
