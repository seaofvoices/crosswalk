#!/bin/sh

set -ex

# Test darklua processed artifacts
lune build-assets

run-in-roblox --place ./test-places/server-loader.rbxl --script ./scripts/run-tests-model.lua
run-in-roblox --place ./test-places/server-loader-debug.rbxl --script ./scripts/run-tests-model.lua
run-in-roblox --place ./test-places/client-loader.rbxl --script ./scripts/run-tests-model.lua
run-in-roblox --place ./test-places/client-loader-debug.rbxl --script ./scripts/run-tests-model.lua
