#!/bin/sh

set -ex

rojo build . -o test-place.rbxlx
run-in-roblox ./test-place.rbxlx -s ./bin/run-tests.lua
