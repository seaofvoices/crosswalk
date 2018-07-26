# crosswalk
This framework wraps the remote events and remote functions calls in order to speed up development.

---

## How it works
Create three folders in your place, for the __Server modules__, the __Client modules__ and the __Shared modules__.
Then, call the `ServerLoader` in a [`Script`](http://robloxdev.com/api-reference/class/Script) and
pass a table that contains your configuration. For example, see [`Main.server`](src/Main.server.lua).
Similarly, call the `ClientLoader` in a [`LocalScript`](http://robloxdev.com/api-reference/class/LocalScript) with its
configuration table. Again, see [`ClientMain.client`](src/ClientMain.client.lua) as a reference. Notice that the
__Server modules__ are not part of the `ClientLoader` configuration.

---

### Server modules
#### Structure
Learn how to write a server module for `crosswalk`.

##### Creating a remote
Here is the special syntax that allows you to create new remotes connected to your functions.

#### How to call other modules
##### Server modules
Learn how to call another server module.

##### Client modules
Learn how to easily call a module located on the client.

##### Shared modules
Learn how to call a shared module.

#### Security
Learn what `_danger` and `_risky` does to your events and functions.

---

### Client modules
#### Structure
Learn how to write a client module for `crosswalk`

#### Creating a remote
Here is the special syntax that allows you to create new remotes connected to your functions.

#### How to call other modules
##### Server modules
Learn how to call another server module.

##### Client modules
Learn how to easily call a module located on the client.

##### Shared modules
Learn how to call a shared module.

---

### Special Functions
#### Init
When this function is defined in a module, it will be called without any arguments.

#### Start
When all the modules are loaded, and every `Init` function has run, it's time for all the defined `Start`
functions to be ran.

---

### Shared modules
These are special modules that are required from both server and client.
