# Server Loader

## API

### Constructor

To construct a new ServerLoader object, call the `new` function:

```lua
ServerLoader.new(configuration)
```

The `configuration` parameter is a table that contains the values presented here.

| field | type | description |
| -- | -- | -- |
| `serverModules` | [ModuleScript](https://developer.roblox.com/en-us/api-reference/class/ModuleScript) list | a list of server modules to load |
| `clientModules` | [ModuleScript](https://developer.roblox.com/en-us/api-reference/class/ModuleScript) list | a list of client modules to load |
| `sharedModules` | [ModuleScript](https://developer.roblox.com/en-us/api-reference/class/ModuleScript) list | a list of shared modules to load |
| `onSecondPlayerRequest` | `function` (optional) | a function that gets called when a player tries to obtain de initial remote setup information more than once |
| `onKeyError` | `function` (optional) | a function that gets called when a player sends the wrong key to a remote |
| `onKeyMissing` | `function` (optional) | a function that gets called when a player calls a remote |
| `onUnapprovedExecution` | `function` (optional) | a function that gets called when a call to a server module function exposed to clients does not validate and the server module does not have a `OnUnapprovedExecution` function defined |
| `remoteCallMaxDelay` | `number` (optional) | the maximum amount of time the server waits for players to send back data when doing a remote function request |

### `start`

To initialize crosswalk on the server side, call the `start` method on the `ServerLoader` object:

```lua
-- first, create a new object
local serverLoader = ServerLoader.new({
    serverModules = ServerStorage.ServerModules:GetChildren(),
    clientModules = ReplicatedStorage.ClientModules:GetChildren(),
    sharedModules = ReplicatedStorage.SharedModules:GetChildren(),
})
-- start crosswalk!
serverLoader:start()
```
