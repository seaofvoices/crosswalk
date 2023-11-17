#!/bin/sh

set -e

rm -rf build

./scripts/build-assets.sh .darklua-dev.json5 place-template.project.json build/debug place-template.rbxl
./scripts/build-assets.sh .darklua.json5 place-template.project.json build place-template.rbxl

lune extract-assets build/debug/place-template.rbxl
lune extract-assets build/place-template.rbxl

TESTS=true ./scripts/build-assets.sh .darklua-dev.json5 test-place.project.json build/debug test-place.rbxl
TESTS=true ./scripts/build-assets.sh .darklua.json5 test-place.project.json build test-place.rbxl

darklua process --config .darklua-bundle.json5 node_modules/crosswalk-client-main/ClientMain.client.lua build/crosswalk-main-client.lua
darklua process --config .darklua-dev-bundle.json5 node_modules/crosswalk-client-main/ClientMain.client.lua build/debug/crosswalk-main-client.lua

darklua process --config .darklua-bundle.json5 node_modules/crosswalk-server-main/Main.server.lua build/crosswalk-main-server.lua
darklua process --config .darklua-dev-bundle.json5 node_modules/crosswalk-server-main/Main.server.lua build/debug/crosswalk-main-server.lua
