## Functions

crosswalk is able to call functions with specific names for you. The following section will list and explain what those functions are. All you have to do is to declared them in any crosswalk module and they will be call automatically.

### Init

The `Init` function is the first function called in a module by crosswalk. Each function is ran one after another, so it is important that any `Init` function does not block (i.e. don't do infinite loops there). The order in which the functions are ran is random.

```lua
function module.Init()
    -- initialize stuff here
end
```

### Start

After running each `Init` functions for all the server modules, crosswalk will run each `Start` function. So it is safe to assume that each `Init` function has been called, but you can't assume any other `Start` function is ran before another. These functions are ran sequentially, so they must not loop indefinitely, just like [`Init`](#init) functions.

```lua
function module.Start()
    -- initialize stuff here after `Init`
end
```

### OnPlayerReady

Instead of connecting to the [`PlayerAdded`](https://developer.roblox.com/en-us/api-reference/event/Players/PlayerAdded) event, use this function. This will ensure that crosswalk is all initialized, so all module communication is ready.

```lua
function module.OnPlayerReady(player)
    -- called after `Init` and `Start` with the player object
end
```

### OnPlayerLeaving

This function removes the need to connect to the [`PlayerRemoving`](https://developer.roblox.com/en-us/api-reference/event/Players/PlayerRemoving) event. This will ensure that crosswalk is all initialized, so all module communication is ready.

```lua
function module.OnPlayerLeaving(player)
    -- called with the player object
end
```

!!! Important
    The `OnPlayerLeaving` function is only available for server modules. It will not be called if used in client modules.
