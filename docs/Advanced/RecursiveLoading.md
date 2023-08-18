# Recursive Loading

crosswalk is able to recursively load modules from the provided root modules. This process works with client, server and shared modules.

Lifecycle functions will still be respected, so that `Init` functions are always called before `Start`, followed by `OnPlayerReady` functions (the latter for client and server modules).

Each type of function will get called from the top level to the deepest level. For example, given this structure of modules:

- `A`
    - `A-1`
        - `A-1-1`
    - `A-2`
    - `A-3`
- `B`
    - `B-1`

The `Init` functions would be called that way:

1. `A`, `B`
1. `A-1`, `A-2`, `A-3`
1. `B-1`
1. `A-1-1`

## Encapsulation

Modules within modules have access to all their descendants, siblings, ancestors and ancestors' siblings. Given the same structure from the previous section, it would give:

| Module | Can access | *Can't access* |
| --- | --- | --- |
| `A` | `A-1`, `A-1-1`, `A-2`, `A-3`, `B` | `B-1` |
| `B` | `A`, `B-1` | `A-1`, `A-1-1`, `A-2`, `A-3` |
| `A-1` | `A`, `A-1-1`, `A-2`, `A-3`, `B` | `B-1` |
| `A-2` | `A`, `A-1`, `A-3`, `B` | `B-1`, `A-1-1` |
| `A-3` | `A`, `A-1`, `A-2`, `B` | `B-1`, `A-1-1` |
| `B-1` | `A`, `B` | `A-1`, `A-1-1`, `A-2`, `A-3` |
| `A-1-1` | `A`, `A-1`, `A-2`, `A-3`, `B` | `B-1` |
