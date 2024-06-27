#!/bin/sh

set -e

DARKLUA_CONFIG=.darklua-dev.json5
ROJO_CONFIG="$1"
BUILD_OUTPUT="$2"
ARTIFACT_NAME="$3"
TEMPLATE_ROJO_CONFIG=place-template.project.json
CODE_OUTPUT=roblox

rm -rf $CODE_OUTPUT
mkdir -p $CODE_OUTPUT

cp -rL node_modules $CODE_OUTPUT/node_modules

mkdir -p $CODE_OUTPUT/rojo

rojo sourcemap rojo/"$TEMPLATE_ROJO_CONFIG" -o "$CODE_OUTPUT"/rojo/sourcemap.json

cp rojo/"$ROJO_CONFIG" "$CODE_OUTPUT"/rojo

TARGET_DARKLUA_CONFIG="$CODE_OUTPUT"/"$DARKLUA_CONFIG"

cp "$DARKLUA_CONFIG" "$TARGET_DARKLUA_CONFIG"

CLIENT_MAIN="$CODE_OUTPUT"/node_modules/crosswalk-client-main/ClientMain.client.lua
darklua process --config "$TARGET_DARKLUA_CONFIG" "$CLIENT_MAIN" "$CLIENT_MAIN"

MAIN="$CODE_OUTPUT"/node_modules/crosswalk-server-main/Main.server.lua
darklua process --config "$TARGET_DARKLUA_CONFIG" "$MAIN" "$MAIN"

mkdir -p "$BUILD_OUTPUT"

rm -f "$BUILD_OUTPUT"/"$ARTIFACT_NAME"

rojo build "$CODE_OUTPUT"/rojo/"$ROJO_CONFIG" -o "$BUILD_OUTPUT"/"$ARTIFACT_NAME"
