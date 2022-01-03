#!/bin/sh

python -m pip install hererocks
hererocks lua_install -r latest --lua=5.1
export PATH=$PATH:$PWD/lua_install/bin

luarocks install luafilesystem
luarocks install busted
luarocks install luacheck
