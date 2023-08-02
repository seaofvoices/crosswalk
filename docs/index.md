# Home

crosswalk is a framework that handles the communication between the server and clients for Roblox games. If you are not familiar with the client-server model itself, you can start with [this article](https://developer.roblox.com/en-us/articles/Roblox-Client-Server-Model).

The framework works by generating and connecting [remote functions and events](https://developer.roblox.com/en-us/articles/Remote-Functions-and-Events) from the definition of your modules. The generated remotes are all hidden behind crosswalk, so you can code your modules on both client and server side and communicate between each of them with a single function call.

crosswalk is designed to make it really easy to communicate between any module from both client and server side. Unfortunately, that comes with a downside: it is also really easy to start making everything connected of everything else! Having too much dependencies in a module will make it hard to modify, since a lot of modules can be affected by the changes.

!!! Warning
    This documentation is work in progress, if you have found typos or if you have any suggestion on what could be added, open an [issue on GitHub](https://github.com/seaofvoices/crosswalk/issues).
