#!/bin/sh

set -e

# Test darklua processed artifacts
TESTS=true ./scripts/build-assets.sh .darklua-dev.json5 test-place.project.json build/debug test-place.rbxl
TESTS=true ./scripts/build-assets.sh .darklua.json5 test-place.project.json build test-place.rbxl

run-in-roblox --place build/test-place.rbxl --script ./scripts/run-tests.lua
run-in-roblox --place build/debug/test-place.rbxl --script ./scripts/run-tests.lua
