# Client Loader

If you want to override the default main client script, this section will be helpful. The `ClientLoader` object is what controls the whole crosswalk lifecycle: it will load the given modules, connect to remotes sent from the server and run special functions.

## Overriding the Default Entrypoint

Although it may seem like an obvious step, make sure that you are not using the default provided ClientMain script.

1. Create a new entrypoint to initialize crosswalk. Insert a [LocalScript](https://developer.roblox.com/en-us/api-reference/class/LocalScript) in [ReplicatedFirst](https://developer.roblox.com/en-us/api-reference/class/ReplicatedFirst) or [StarterPlayerScripts](https://developer.roblox.com/en-us/api-reference/class/StarterPlayerScripts) for example.
1. In that script, require the `ClientLoader` class.
1. Create a new object of that class using the [`new`](#constructor) constructor. It should look like `local loader = ClientLoader.new({ ... })`. Three list should be provided to the constructor, one for each kind of modules (server, client and shared).
1. Call the [`start`](#start) method.

Overall, it should be similar to this:

```lua
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local ClientLoader = require(ReplicatedStorage:WaitForChild('ClientLoader'))

local loader = ClientLoader.new({
    clientModules = ReplicatedStorage:WaitForChild('ClientModules'):GetChildren(),
    sharedModules = ReplicatedStorage:WaitForChild('SharedModules'):GetChildren(),
    -- put other configuration values to override:
    -- to provide modules that are not going to get linked and connected by
    -- crosswalk, use `externalModules`
    externalModules = {
        Llama = require(ReplicatedStorage:WaitForChild('Llama')),
        Roact = require(ReplicatedStorage:WaitForChild('Roact')),
    },
    -- this will make crosswalk print a bunch of information to the output
    logLevel = 'debug',
})
loader:start()
```

## API

### Constructor

To construct a new `ClientLoader` object, call the `new` function:

```lua
ClientLoader.new(configuration)
```

The `configuration` parameter is a table that contains the values presented here.

| field | type | description |
| -- | -- | -- |
| `clientModules` | [ModuleScript](https://developer.roblox.com/en-us/api-reference/class/ModuleScript) list | a list of client modules to load |
| `sharedModules` | [ModuleScript](https://developer.roblox.com/en-us/api-reference/class/ModuleScript) list | a list of shared modules to load |
| `externalModules` | `{ [string]: any }` | a dictionary that maps a module name to its implementation |
| `logLevel` | `'error'`, `'warn'`, `'info'` or `'debug'` | Defines what will crosswalk's reporter outputs to the console. Default is `'warn'` |

### `start`

To initialize crosswalk on the client side, call the `start` method on the `ClientLoader` object:

```lua
-- first, create a new object
local clientLoader = ClientLoader.new({
    clientModules = ReplicatedStorage.ClientModules:GetChildren(),
    sharedModules = ReplicatedStorage.SharedModules:GetChildren(),
    logLevel = 'warn',
})
-- start crosswalk!
clientLoader:start()
```
