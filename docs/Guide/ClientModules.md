# Client Modules

## Structure

```lua
return function(Modules, ServerModules, Services)
    local module = {}

    -- function definitions

    return module
end
```

| argument | description |
| -- | -- |
| Modules | A table that contains all the other client modules |
| ServerModules | A table with all the server module functions exposed to the client |
| Services | A table to access Roblox services, handy when you want to test your modules |

## Calling Client Modules

The `Modules` table makes it really easy to communicate with any other client modules. All you need is to index the table with the module name and then you can access its functions. For example, if you have a module called `ModuleA` that defines a function named `Print`:

```lua
-- ClientModules/ModuleA.lua
return function(Modules, ServerModules, Services)
    local module = {}

    function module.Print(value)
        print('from ModuleA:', value)
    end

    return module
end
```

You can access the ModuleA from any other client module by using `Modules.ModuleA`:

```lua
-- ClientModules/ModuleB.lua
return function(Modules, ServerModules, Services)
    local module = {}

    function module.Example()
        Modules.ModuleA.Print('foo')
    end

    return module
end
```

## Calling Server Modules

The `ServerModules` table works exactly like the `Modules` table, except that you will only be able to call functions that are exposed as remote events or remote functions (ending with `_event` or `_func`). For example:

```lua
ServerModules.Example.Print("Hello")
```

More information can be found on the [server module page](ServerModules.md#from-client-modules).

## Exposing Functions to Server Modules

In order to be able to call a function from any server modules, a suffix needs to be added to the function name. There is only two suffixes that you can use, which depends on the type of function you have.

| suffix | use case |
| -- | -- |
| `_event` | for functions that do not return any value |
| `_func` | for functions that returns something |

The next example shows the three possible types for a function in a client module.

=== "Void"
    ```lua
    -- the DoSomething function is callable from client modules and server modules.
    -- the server won't receive any return value
    return function(Modules, ClientModules, Services)
        local module = {}

        function module.DoSomething_event()
            print('DoSomething called!')
        end

        return module
    end
    ```
=== "Return value"
    ```lua
    -- the DoSomething function is callable from client modules and server modules.
    -- the return value will be sent back to the server when it's called
    return function(Modules, ClientModules, Services)
        local module = {}

        function module.DoSomething_func()
            return 'DoSomething called!'
        end

        return module
    end
    ```
=== "Default"
    ```lua
    -- the DoSomething function is callable only from other client modules
    return function(Modules, ClientModules, Services)
        local module = {}

        function module.DoSomething()
            print('DoSomething called!')
        end

        return module
    end
    ```

## Calling Exposed Functions

Even if the function name ends with a suffix, exposed functions are called without their suffix. That means that if a function is declared as `DoSomething_event`, `DoSomething_func`, you can call it using only `DoSomething`.

### From Server Modules

Since the call is made from the server to the client module, you need to provide the player which will be invoked, but that parameter won't be passed to the client function. The following example

=== "SomeServerModule"
    ```lua
    return function(Modules, ClientModules, Services)
        local module = {}

        function module.SayHelloToPlayer(player)
            ClientModules.SomeClientModule.PrintToLocalConsole(player, 'Hello')
        end

        return module
    end
    ```
=== "SomeClientModule"
    ```lua
    return function(Modules, ServerModules, Services)
        local module = {}

        function module.PrintToLocalConsole_event(message)
            print('LocalConsole:', message)
        end

        return module
    end
    ```

You can also call every client by appending `All` to the function name. So for example, if you want to call the function from the previous example to all players, you can use the function name appended with `All` function.

=== "All players"
    ```lua
    -- call all players in the game
    ClientModules.SomeClientModule.PrintToLocalConsoleAll('Hello')
    ```
=== "Single player"
    ```lua
    -- call one specific player
    ClientModules.SomeClientModule.PrintToLocalConsole(player, 'Hello')
    ```

### From Client Modules

Even if the function is exposed to server modules, you can also call it from other client modules. Here is an example with a module named ModuleA that calls ModuleB:

=== "ModuleA"
    ```lua
    return function(Modules, ServerModules, Services)
        local module = {}

        function module.Greet(player)
            Modules.ModuleB.PrintToLocalConsole('Welcome!')
        end

        return module
    end
    ```
=== "ModuleB"
    ```lua
    return function(Modules, ServerModules, Services)
        local module = {}

        function module.PrintToLocalConsole_event(message)
            print('LocalConsole:', message)
        end

        return module
    end
    ```
