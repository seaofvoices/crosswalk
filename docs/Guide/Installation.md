# Installation

crosswalk has two necessary dependency, the client loader and the server loader. Along with this, it comes with two default booting scripts. Except if you have a very particular use-case, you should use the default boot scripts. The next table shows where you should put each of the assets into the Roblox game.

| asset | parent instance |
| -- | -- |
| Client Loader | [ReplicatedFirst](https://developer.roblox.com/en-us/api-reference/class/ReplicatedFirst) |
| Server Loader | [ServerStorage](https://developer.roblox.com/en-us/api-reference/class/ServerStorage) |
| Client Main | [ReplicatedFirst](https://developer.roblox.com/en-us/api-reference/class/ReplicatedFirst) |
| Server Main| [ServerScriptService](https://developer.roblox.com/en-us/api-reference/class/ServerScriptService) |

After, all you need to do is insert three folders into the game that will contain your modules. You can find more information about this on the [Getting Started](GettingStarted.md#project-structure) page.

## Roblox Models

You can also download these Roblox model files and insert them into your game.

| asset | current master version |
| -- | -- |
| Client Loader | [client-loader.rbxm](../releases/master/client-loader.rbxm) |
| Server Loader | [server-loader.rbxm](../releases/master/server-loader.rbxm) |
| Client Main | [client-main.rbxm](../releases/master/client-main.rbxm) |
| Server Main| [server-main.rbxm](../releases/master/server-main.rbxm) |

## As a Git Submodule

To add the project as a git submodule into an existing git repository, run

```
git submodule add https://gitlab.com/seaofvoices/crosswalk.git modules/crosswalk
```

This will insert it in a folder named `modules` under the root of the repository, but you can put it anywhere you want.

If you are using [Rojo](https://rojo.space/) to sync (or build) your project, all you need to do is to modify your configuration file to tell Rojo where to put crosswalk's assets. With the default client and server loaders included in crosswalk, the project file should contain the following information:

```json
{
    "tree": {
        "$className": "DataModel",
        "ReplicatedFirst": {
            "$className": "ReplicatedFirst",
            "ClientLoader": {
                "$path": "path/to/crosswalk/src/ClientLoader"
            },
            "ClientMain": {
                "$path": "path/to/crosswalk/src/ClientMain.client.lua"
            }
        },
        "ServerScriptService": {
            "$className": "ServerScriptService",
            "Main": {
                "$path": "path/to/crosswalk/src/Main.server.lua"
            }
        },
        "ServerStorage": {
            "$className": "ServerStorage",
            "ServerLoader": {
                "$path": "path/to/crosswalk/src/ServerLoader"
            }
        }
    }
}
```
