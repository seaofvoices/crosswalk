# Server Modules

## Structure

```lua
return function(Modules, ClientModules, Services)
    local module = {}

    -- function definitions

    return module
end
```

| argument | description |
| -- | -- |
| Modules | A table that contains all the other server modules |
| ClientModules | A table with all the client module functions exposed to the server |
| Services | A table to access Roblox services, handy when you want to test your modules |

## Calling Server Modules

The `Modules` table makes it really easy to communicate with any other server modules. All you need is to index the table with the module name and then you can access its functions. For example, if you have a module called `ModuleA` that defines a function named `Print`:

```lua
-- ServerModules/ModuleA.lua
return function(Modules, ClientModules, Services)
    local module = {}

    function module.Print(value)
        print('from ModuleA:', value)
    end

    return module
end
```

You can access the ModuleA from any other module server module by using `Modules.ModuleA`:

```lua hl_lines="6"
-- ServerModules/ModuleB.lua
return function(Modules, ClientModules, Services)
    local module = {}

    function module.Example()
        Modules.ModuleA.Print('foo')
    end

    return module
end
```

!!! Warning
    You can't access the `Modules` and `ClientModules` in the scope of the function that returns the module itself, since the table may not have been populated yet with the other modules. Always call other module functions inside one of your module's function.

    === "Good"
        ```lua hl_lines="7"
        return function(Modules, ClientModules, Services)
            local module = {}

            local value = nil

            function module.Init()
                value = Modules.OtherModule.ItsFunction()
            end

            return module
        end
        ```
    === "Wrong"
        ```lua hl_lines="4"
        return function(Modules, ClientModules, Services)
            local module = {}

            local value = Modules.OtherModule.ItsFunction()

            return module
        end
        ```

## Calling Client Modules

The `ClientModules` table works exactly like the `Modules` table, except that you will only be able to call functions that are exposed as remote events or remote functions (ending with `_event` or `_func`).

Also, since you are calling from the server to a client, you need to specify which player are you calling to, by placing the player object as the first argument.

You can find more information about this on the [client module page](ClientModules.md#from-server-modules).

## Exposing Functions to Client Modules

crosswalk allow server modules to define functions that can be called from any client modules. In order to explain how to do achieve this, follow the next example.

### Example

In order to be able to call a function from any client modules, a suffix needs to be added to the function name. For the example used with this section, we will use two variant of the same function, with and without a return value:

=== "Void"
    ```lua
    function module.IncreaseCounter(amount)
        counter = counter + amount
    end
    ```
=== "Returning"
    ```lua
    function module.IncreaseCounter(amount)
        counter = counter + amount
        return counter
    end
    ```

If you want to it to be called from any client modules, a few modifications need to be made:

  - add the appropriate suffix
  - change the signature
  - return the validation value

#### Suffixes

In server modules, different suffixes can be used, which depends on the use case you have. There are two main type of suffixes:

  - `_event`, for functions without a result
  - `_func`, for functions that return a result

Unlike with client modules, a security level can also be specified through a function name. This will determine how crosswalk will wrap up the functions to add a layer of key exchanging mecanism. Under the hood, what is happening is that instead of only sending the given arguments, crosswalk will also send a key to the server. The server will verify that key to make sure that the call is valid.

The default mode is the most secure, where each function call is sent with a different security key. The difference with the `_risky` level is that an initial security key will be set and then used for each call. The last level, `_danger`, will connect directly to the [RemoteEvent](https://developer.roblox.com/en-us/api-reference/class/RemoteEvent) or [RemoteFunction](https://developer.roblox.com/en-us/api-reference/class/RemoteFunction), without any additional code.

| suffix | security |
| -- | -- |
| `_event` or `_func` | Exchanging new security key each call |
| `_risky_event` or `_risky_func` | Exchanging the same security key everytime |
| `_danger_event` or `_danger_func` | No security keys exchanged |

If you need performance, because you need to call the function really often from the client side, you should go with the `_risky` or `_danger` level.

If we update our example, we should have one of these three possibilities:

=== "Void"
    ```lua
    function module.IncreaseCounter_event(amount)
        counter = counter + amount
    end

    function module.IncreaseCounter_risky_event(amount)
        counter = counter + amount
    end

    function module.IncreaseCounter_danger_event(amount)
        counter = counter + amount
    end
    ```
=== "Returning"
    ```lua
    function module.IncreaseCounter_func(amount)
        counter = counter + amount
        return counter
    end

    function module.IncreaseCounter_risky_func(amount)
        counter = counter + amount
        return counter
    end

    function module.IncreaseCounter_danger_func(amount)
        counter = counter + amount
        return counter
    end
    ```

#### Signature

Since the function can be called from any client modules, the first parameter passed to the function will be the [player](https://developer.roblox.com/en-us/api-reference/class/Player) calling the function. This step is easy, simply add a parameter to the function signature:

=== "Void"
    ```lua
    function module.IncreaseCounter_event(player, amount)
        counter = counter + amount
    end
    ```
=== "Returning"
    ```lua
    function module.IncreaseCounter_func(player, amount)
        counter = counter + amount
        return counter
    end
    ```

#### Validation
Since the exposed function is meant to be called from a client module, it needs to return a boolean that validate the execution. For example, you can check if the parameters have the correct type. If you are using the `_func` suffix, that means that your function needs to return its value after the validation.

The function is now exposed to any client modules.

=== "Void"
    ```lua
    function module.IncreaseCounter_event(player, amount)
        if type(amount) ~= 'number' then
            return false
        end

        counter = counter + amount

        return true
    end
    ```
=== "Returning"
    ```lua
    function module.IncreaseCounter_func(player, amount)
        if type(amount) ~= 'number' then
            return false
        end

        counter = counter + amount

        return true, counter
    end
    ```

!!! Important
    This validation is **required**. Any function exposed to clients using `_func` or `_event` must return `true` or `false` to indicate that the function was called with normal values in the right context. This is crucial to be able to react to bad actors that are bypassing the game systems and trying to manually trigger remote functions or remote events.

    This relates to the [special function `OnUnapprovedExecution`](Functions.md#onunapprovedexecution) that is automatically called when this validation process fails.

## Calling Exposed Functions

Even if the function ends a suffix, exposed functions are called without their suffix. That means that if a function is declared as `DoSomething_event`, `DoSomething_risky_event` or with any other suffix, you can call it using only `DoSomething`.

### From Client Modules

Since the call is made from a client to the server module, you don't have to provide the player object, it will be automatically set with the player calling the server module.

=== "SomeClientModule"
    ```lua
    return function(Modules, ServerModules, Services)
        local module = {}

        function module.Greet(player)
            ServerModules.SomeServerModule.SayHello('Welcome!')
        end

        return module
    end
    ```
=== "SomeServerModule"
    ```lua
    return function(Modules, ClientModules, Services)
        local module = {}

        function module.SayHello_event(player, message)
            print('Hello', player.Name, ':', message)

            return true
        end

        return module
    end
    ```

### From Server Modules

Even if the function is exposed to client modules, you can also call it from other server modules. Here is an example with a module named ModuleA that calls ModuleB:

=== "ModuleA"
    ```lua
    return function(Modules, ClientModules, Services)
        local module = {}

        function module.Greet(player)
            Modules.ModuleB.SayHello(player, 'Welcome!')
        end

        return module
    end
    ```
=== "ModuleB"
    ```lua
    return function(Modules, ClientModules, Services)
        local module = {}

        function module.SayHello_event(player, message)
            print('Hello', player.Name, ':', message)

            return true
        end

        return module
    end
    ```
