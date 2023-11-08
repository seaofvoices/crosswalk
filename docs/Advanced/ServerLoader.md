# Server Loader

If you want to override the default main server script, this section will be helpful. The `ServerLoader` object is what controls the whole crosswalk lifecycle: it will load the given modules, connect remotes and run special functions.

## Overriding the Default Entrypoint

Although it may seem like an obvious step, make sure that you are not using the default provided Main script.

1. Create a new entrypoint to initialize crosswalk. Insert a [Script](https://developer.roblox.com/en-us/api-reference/class/Script) in [ServerScriptService](https://developer.roblox.com/en-us/api-reference/class/ServerScriptService) for example.
1. In that script, require the `ServerLoader` class.
1. Create a new object of that class using the [`new`](#constructor) constructor. It should look like `local loader = ServerLoader.new({ ... })`. Three list should be provided to the constructor, one for each kind of modules (server, client and shared).
1. Call the [`start`](#start) method.

Overall, it should be similar to this:

```lua
local ServerStorage = game:GetService('ServerStorage')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local ServerLoader = require(ServerStorage:WaitForChild('ServerLoader'))

local loader = ServerLoader.new({
    serverModules = ServerStorage:WaitForChild('ServerModules'):GetChildren(),
    clientModules = ReplicatedStorage:WaitForChild('ClientModules'):GetChildren(),
    sharedModules = ReplicatedStorage:WaitForChild('SharedModules'):GetChildren(),
    -- put other configuration values to override:
    -- to provide modules that are not going to get linked and connected by
    -- crosswalk, use `externalModules`
    externalModules = {
        Llama = require(ReplicatedStorage:WaitForChild('Llama')),
    },
    -- this will make crosswalk print a bunch of information to the output
    logLevel = 'debug'
    -- kick players that send unexpected input to server functions
    onUnapprovedExecution = function(player)
        player:Kick('Bye')
    end,
    -- ...
})
loader:start()
```

## API

### Constructor

To construct a new `ServerLoader` object, call the `new` function:

```lua
ServerLoader.new(configuration)
```

The `configuration` parameter is a table that contains the values presented here.

| field | type | description |
| -- | -- | -- |
| `serverModules` | [ModuleScript](https://developer.roblox.com/en-us/api-reference/class/ModuleScript) list | a list of server modules to load |
| `clientModules` | [ModuleScript](https://developer.roblox.com/en-us/api-reference/class/ModuleScript) list | a list of client modules to load |
| `sharedModules` | [ModuleScript](https://developer.roblox.com/en-us/api-reference/class/ModuleScript) list | a list of shared modules to load |
| `externalModules` | `{ [string]: any }` | a dictionary that maps a module name to its implementation |
| `logLevel` | `'error'`, `'warn'`, `'info'` or `'debug'` | Defines what will crosswalk's reporter outputs to the console. Default is `'warn'` |
| `onSecondPlayerRequest` | `function` (optional) | a function that gets called when a player tries to obtain de initial remote setup information more than once |
| `onKeyError` | `function` (optional) | a function that gets called when a player sends the wrong key to a remote |
| `onKeyMissing` | `function` (optional) | a function that gets called when a player calls a remote |
| `onUnapprovedExecution` | `function` (optional) | a function that gets called when a call to a server module function exposed to clients does not validate and the server module does not have a `OnUnapprovedExecution` function defined |
| `remoteCallMaxDelay` | `number` (optional) | the maximum amount of time the server waits for players to send back data when doing a remote function request |
| `customModuleFilter` | `(ModuleScript) -> boolean` (optional) | Provide a function to filter modules that are not regular crosswwalk modules. crosswalk will not automatically call `Init`, `Start`, `OnPlayerReady` or `OnPlayerLeaving` functions on these modules. Defaults to a filter that selects ModuleScript with names ending with `Class` |
| `excludeModuleFilter` | `(ModuleScript) -> boolean` (optional) | Provide a function that excludes ModuleScripts from loading at all. Defaults to a filter that removes ModuleScript with names ending with `.spec` or `.test` |

### `start`

To initialize crosswalk on the server side, call the `start` method on the `ServerLoader` object:

```lua
-- first, create a new object
local serverLoader = ServerLoader.new({
    serverModules = ServerStorage.ServerModules:GetChildren(),
    clientModules = ReplicatedStorage.ClientModules:GetChildren(),
    sharedModules = ReplicatedStorage.SharedModules:GetChildren(),
    logLevel = 'warn',
    onSecondPlayerRequest = function(player) --[[ ... ]] end,
    onKeyError = function(player, moduleName, functionName) --[[ ... ]] end,
    onKeyMissing = function(player, moduleName, functionName) --[[ ... ]] end,
    onUnapprovedExecution = function(player, info)
        warn(
            ('Function %s.%s called by player `%s` (id:%d) was not approved'):format(
                info.moduleName,
                info.functionName,
                player.Name,
                player.UserId
            )
        )
    end,
    remoteCallMaxDelay = 2,
})
-- start crosswalk!
serverLoader:start()
```
