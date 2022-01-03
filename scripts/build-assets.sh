#!/bin/sh

set -ex

mkdir -p build

mkdir -p build/temp

cp -r rojo build/temp

# build production artifacts
darklua process --config-path scripts/darklua/prod.json5 src build/temp/src

rojo build build/temp/rojo/server-loader.project.json -o build/server-loader.rbxm
rojo build build/temp/rojo/client-loader.project.json -o build/client-loader.rbxm
rojo build build/temp/rojo/server-main.project.json -o build/server-main.rbxm
rojo build build/temp/rojo/client-main.project.json -o build/client-main.rbxm

# clean up processed source code
rm -fr build/temp/src

# build debug artifacts
darklua process --config-path scripts/darklua/debug.json5 src build/temp/src

mkdir -p build/debug

rojo build build/temp/rojo/server-loader.project.json -o build/debug/server-loader.rbxm
rojo build build/temp/rojo/client-loader.project.json -o build/debug/client-loader.rbxm
rojo build build/temp/rojo/server-main.project.json -o build/debug/server-main.rbxm
rojo build build/temp/rojo/client-main.project.json -o build/debug/client-main.rbxm

# build test places

mkdir -p test-places

cp build/server-loader.rbxm build/model.rbxm
rojo build rojo/test-model.project.json -o test-places/server-loader.rbxl

cp build/debug/server-loader.rbxm build/model.rbxm
rojo build rojo/test-model.project.json -o test-places/server-loader-debug.rbxl

cp build/client-loader.rbxm build/model.rbxm
rojo build rojo/test-model.project.json -o test-places/client-loader.rbxl

cp build/debug/client-loader.rbxm build/model.rbxm
rojo build rojo/test-model.project.json -o test-places/client-loader-debug.rbxl

# clean up temporary files and directories

rm -fr build/temp
rm build/model.rbxm

# remove tests

remodel run remove-tests build
