#!/bin/sh

set -e

rm -rf build

./scripts/build-workspace.sh crosswalk-client .darklua-dev.json5 build/debug ClientLoader client-loader.rbxm
./scripts/build-workspace.sh crosswalk-client .darklua.json5 build ClientLoader client-loader.rbxm

./scripts/build-workspace.sh crosswalk-server .darklua-dev.json5 build/debug ServerLoader server-loader.rbxm
./scripts/build-workspace.sh crosswalk-server .darklua.json5 build ServerLoader server-loader.rbxm

yarn install
yarn prepare

./scripts/build-main.sh client-main.project.json build client-main.rbxm
./scripts/build-main.sh server-main.project.json build server-main.rbxm

darklua process --config .darklua-bundle.json5 node_modules/crosswalk-client-main/ClientMain.client.lua build/crosswalk-main-client.lua
darklua process --config .darklua-dev-bundle.json5 node_modules/crosswalk-client-main/ClientMain.client.lua build/debug/crosswalk-main-client.lua

darklua process --config .darklua-bundle.json5 node_modules/crosswalk-server-main/Main.server.lua build/crosswalk-main-server.lua
darklua process --config .darklua-dev-bundle.json5 node_modules/crosswalk-server-main/Main.server.lua build/debug/crosswalk-main-server.lua
