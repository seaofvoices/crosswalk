# Installation

crosswalk has two code dependencies, the **client loader** and the **server loader**. Along with this, it comes with two default main scripts.

| asset | parent instance |
| -- | -- |
| Client Loader | [ReplicatedStorage](https://developer.roblox.com/en-us/api-reference/class/ReplicatedStorage) |
| Server Loader | [ServerStorage](https://developer.roblox.com/en-us/api-reference/class/ServerStorage) |
| Client Main | [StarterPlayerScripts](https://developer.roblox.com/en-us/api-reference/class/StarterPlayerScripts) or [ReplicatedFirst](https://developer.roblox.com/en-us/api-reference/class/ReplicatedFirst) |
| Server Main| [ServerScriptService](https://developer.roblox.com/en-us/api-reference/class/ServerScriptService) |

After, all you need to do is insert three folders into the game that will contain your modules. You can find more information about this on the [Getting Started](GettingStarted.md#project-structure) page.

## Roblox Models

You can also download these Roblox model files and insert them into your game. These models are built from the latest main branch.

| asset | develop | production |
| -- | -- | -- |
| Client Loader | [client-loader.rbxm](../releases/main/debug/client-loader.rbxm) | [client-loader.rbxm](../releases/main/client-loader.rbxm) |
| Server Loader | [server-loader.rbxm](../releases/main/debug/server-loader.rbxm) | [server-loader.rbxm](../releases/main/server-loader.rbxm) |
| Client Main | [client-main.rbxm](../releases/main/debug/client-main.rbxm) | [client-main.rbxm](../releases/main/client-main.rbxm) |
| Server Main | [server-main.rbxm](../releases/main/debug/server-main.rbxm) | [server-main.rbxm](../releases/main/server-main.rbxm) |

!!! Important
    The difference between the develop and production builds is that warnings and verifications are removed from the production builds.

## Quick Install

For a quick install, crosswalk is also available as two bundled files, the server main script and the client main script. Note that if you wish to customize the entry points, these bundled scripts are not made for that.

| asset | develop | production |
| -- | -- | -- |
| Client Main (bundled) | [crosswalk-main-client.lua](../releases/main/debug/crosswalk-main-client.lua) | [crosswalk-main-client.lua](../releases/main/crosswalk-main-client.lua) |
| Server Main (bundled) | [crosswalk-main-server.lua](../releases/main/debug/crosswalk-main-server.lua) | [crosswalk-main-server.lua](../releases/main/crosswalk-main-server.lua) |

## Using the `npm` Packages

Add `crosswalk-client` and `crosswalk-server` in your dependencies:

```bash
yarn add crosswalk-client crosswalk-server
```

Or if you are using `npm`:

```bash
npm install crosswalk-client crosswalk-server
```
