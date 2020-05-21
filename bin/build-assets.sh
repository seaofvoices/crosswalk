#!/bin/sh

set -ex

mkdir -p build

rojo build rojo/server-loader.project.json -o build/server-loader.rbxm
rojo build rojo/client-loader.project.json -o build/client-loader.rbxm
rojo build rojo/server-main.project.json -o build/server-main.rbxm
rojo build rojo/client-main.project.json -o build/client-main.rbxm

remodel run remove-tests
