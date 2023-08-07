export type CrosswalkModule = {
    Init: (() -> ())?,
    Start: (() -> ())?,
    OnPlayerReady: ((Player) -> ())?,
}

local function requireModule<T...>(moduleScript: ModuleScript, ...: T...): CrosswalkModule
    local success, moduleLoader = pcall(require, moduleScript)
    if not success then
        error(('Error while loading module %q : %s'):format(moduleScript.Name, moduleLoader))
    end

    local loaded, module = pcall(moduleLoader, ...)
    if not loaded then
        error(('Error while calling the module loader %q : %s'):format(moduleScript.Name, module))
    end

    return module
end

return requireModule
