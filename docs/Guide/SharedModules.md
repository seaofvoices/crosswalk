# Shared Modules

## Structure

```lua
return function(SharedModules, Services, isServer)
    local module = {}

    return module
end
```

| argument | description |
| -- | -- |
| SharedModules | A table that contains all the other shared modules |
| Services | A table to access Roblox services, handy when you want to test your modules |
| isServer | A boolean that indicates if the shared module is loaded from the server or the client |

## Calling Shared Modules

The `SharedModules` table makes it really easy to communicate with any other shared modules. All you need is to index the table with the module name and then you can access its functions. For example, if you have a first module called `ModuleA` that defines a function named `Print`:

```lua
-- SharedModules/ModuleA.lua
return function(SharedModules, Services, isServer)
    local module = {}

    function module.Print(value)
        print('from ModuleA:', value)
    end

    return module
end
```

You can access the ModuleA from any other module by getting it from the `SharedModules` table as `SharedModules.ModuleA`:

```lua hl_lines="6"
-- SharedModules/ModuleB.lua
return function(SharedModules, Services, isServer)
    local module = {}

    function module.Example()
        SharedModules.ModuleA.Print('foo')
    end

    return module
end
```
