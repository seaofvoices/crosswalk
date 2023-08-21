local function defaultExcludeModuleFilter(moduleScript: ModuleScript): boolean
    return moduleScript.Name:match('%.spec$') ~= nil or moduleScript.Name:match('%.test$') ~= nil
end

return defaultExcludeModuleFilter
