# Quick Reference

## Client Modules
[Link to complete guide](Guide/ClientModules.md)

### Structure
```lua
return function(Modules, ClientModules, Services)
    local module = {}

    return module
end
```

### Remotes

Since functions exposed in client modules are meant to be called from the server, the communication can be trusted. That is why there is no variant on security levels.

| suffix | description |
| -- | -- |
| _event | Callable from server modules |
| _func | Callable from server modules with a return value |

---

## Server Modules
[Link to complete guide](Guide/ServerModules.md)

### Structure
```lua
return function(Modules, ClientModules, Services)
    local module = {}

    return module
end
```

### Remotes

To expose a function as callable from the client (using a [RemoteEvent](https://developer.roblox.com/en-us/api-reference/class/RemoteEvent)):

| suffix | security |
| -- | -- |
| _event | Exchanging new security key each call |
| _risky_event | Exchanging the same security key everytime |
| _danger_event | No security keys exchanged |

To expose a function as callable from the client but with a return value (using a [RemoteFunction](https://developer.roblox.com/en-us/api-reference/class/RemoteFunction)):

| suffix | security |
| -- | -- |
| _func | Exchanging new security key each call |
| _risky_func | Exchanging the same security key everytime |
| _danger_func | No security keys exchanged |

!!! Remember
    Since the exposed function is meant to be called from a client module, the function needs to return a boolean that validate the execution. See the [server modules guide](Guide/ServerModules.md#validation) for more info.

---

## Shared Modules
[Link to complete guide](Guide/SharedModules.md)

### Structure
```lua
return function(isServer, SharedModules, Services)
    local module = {}

    return module
end
```

---

## Functions

| name | parameters | description |
| -- | -- | -- |
| Init | | First function called |
| Start | | Called after all `Init` functions |
| OnPlayerReady | [Player](https://developer.roblox.com/en-us/api-reference/class/Player) | Called after `Init` and `Start` with the local player |
| OnPlayerLeaving | [Player](https://developer.roblox.com/en-us/api-reference/class/Player) | Called when a player leaves the game (only in server modules) |
| OnUnapprovedExecution | [Player](https://developer.roblox.com/en-us/api-reference/class/Player), info table | Called when a player calls a server module function that does not validate |
