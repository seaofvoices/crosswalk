# Getting Started

## How It Works

crosswalk is a framework that handles the communication between clients and server. It abstracts all the remote events and remote functions your game needs.

You don't have to call crosswalk. Instead, it will load your modules and initialize everything for you. In order to do that, modules need to have a specific structure that crosswalk can understand. The basic structure is really simple, all you need is to define a function that will build the module.

There is more information in the next pages about how to create crosswalk modules, but here is a quick preview of what it looks like:

=== "Client module"
    ```lua
    return function(Modules, ServerModules, Services)
        local module = {}

        function module.DoSomething()

        end

        return module
    end
    ```
=== "Server module"
    ```lua
    return function(Modules, ClientModules, Services)
        local module = {}

        function module.DoSomething()

        end

        return module
    end
    ```
=== "Shared module"
    ```lua
    return function(SharedModules, Services, isServer)
        local module = {}

        function module.DoSomething()

        end

        return module
    end
    ```

Each crosswalk module is a [ModuleScript](https://developer.roblox.com/en-us/api-reference/class/ModuleScript) that returns a function to build a table that contains the actual module functions. It is those functions, like the `DoSomething` function in the previous example, that will be accessible from other crosswalk modules.

## Project Structure

When using crosswalk, your project should be divided into three folders:

  - Server modules
  - Client modules
  - Shared modules

As for where these folders should be into a place, the only restriction is that the shared modules and client modules must be accessible from both the client and the server and the server modules accessible from the server (obviously). However, if you are using the default module loaders (also referred as the boot scripts or main scripts), the next section will explain where to put those folders and what name they should have.

### Using the default module loaders

crosswalk comes with two default module loaders, one for the [client modules](https://gitlab.com/seaofvoices/crosswalk/-/blob/master/src/ClientMain.client.lua) and one for the [server modules](https://gitlab.com/seaofvoices/crosswalk/-/blob/master/src/Main.server.lua). In order to use those scripts, simply put the client main under [ReplicatedFirst](https://developer.roblox.com/en-us/api-reference/class/ReplicatedFirst) and the server main under [ServerScriptService](https://developer.roblox.com/en-us/api-reference/class/ServerScriptService).

If you are using the default client and server loader from crosswalk, you are expected to provide three folders:

| folder name | parent |
| -- | -- |
| ServerModules | ServerStorage |
| ClientModules | ReplicatedStorage |
| SharedModules | ReplicatedStorage |

Then, all you have to do is put [ModuleScripts](https://developer.roblox.com/en-us/api-reference/class/ModuleScript) inside those folders and the default loader will automatically load every modules.

## Modules

Think about a module as if it was a service. It should provide capabilities by itself or offer capabilities to other modules. When thinking in modules, it is also usually better to tell a module to do something, rather then asking for their current state and then make them do something from that state (read about the *Tell Don't Ask Principle* if you want to know more).

The next sections of this guide will present the different types of modules in crosswalk. You will find more specific information about [client modules](ClientModules.md), [server modules](ServerModules.md) and [shared modules](SharedModules.md)
