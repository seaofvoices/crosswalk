#!/bin/sh

set -ex

rojo build . -o test-place.rbxlx

run-in-roblox --place ./test-place.rbxlx --script ./scripts/run-tests-dev.lua
run-in-roblox --place ./test-place.rbxlx --script ./scripts/run-tests.lua

# Test darklua processed artifacts
./scripts/build-assets.sh

mkdir -p ./test-places

run-in-roblox --place ./test-places/server-loader.rbxl --script ./scripts/run-tests-model.lua
run-in-roblox --place ./test-places/server-loader-debug.rbxl --script ./scripts/run-tests-model.lua
run-in-roblox --place ./test-places/client-loader.rbxl --script ./scripts/run-tests-model.lua
run-in-roblox --place ./test-places/client-loader-debug.rbxl --script ./scripts/run-tests-model.lua

rm -rf ./test-places
