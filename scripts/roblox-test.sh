#!/bin/sh

set -e

DARKLUA_CONFIG=".darklua-tests.json"

if [ ! -d node_modules ]; then
    yarn install
fi
if [ ! -d node_modules/.luau-aliases ]; then
    yarn prepare
fi

rm -rf temp

rojo sourcemap rojo/jest-place.project.json -o rojo/sourcemap.json

darklua process --config $DARKLUA_CONFIG node_modules temp/node_modules
darklua process --config $DARKLUA_CONFIG scripts/roblox-test.server.lua temp/scripts/roblox-test.server.lua

mkdir -p temp/rojo/
cp rojo/jest-place.project.json temp/rojo/

rojo build temp/rojo/jest-place.project.json -o temp/test-place.rbxl

run-in-roblox --place temp/test-place.rbxl --script temp/scripts/roblox-test.server.lua

rm -rf temp
