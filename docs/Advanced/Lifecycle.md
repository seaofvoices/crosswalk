# Lifecycle

Now that you have learned about the special functions that crosswalk calls when they are defined within a server, client or shared modules, you may wonder when each of them are happening.

## Server Lifecycle

When initializing the server, crosswalk will go through the following steps:

- Call shared modules `Init` functions
- Call server modules `Init` functions
- Setup remote events and remote functions
- Call shared modules `Start` functions
- Call server modules `Start` functions

### Player Join

When a player joins the server:

- Setup player communication with remote events and remote functions.
- Call server modules `OnPlayerReady` functions (all `Init` and `Start` functions have been called before this point)

### Player Leaving

When a player leaves the server, crosswalk will do:

- Call server modules `OnPlayerLeaving` functions.

## Client Lifecycle

When initializing a client, crosswalk will go through these steps:

- Call shared modules `Init` functions
- Call client modules `Init` functions
- Call shared modules `Start` functions
- Call client modules `Start` functions
- Setup remote events and remote functions
- Tell server that the client is ready, which triggers the calls to `OnPlayerReady` server functions
- Call client modules `OnPlayerReady` functions
