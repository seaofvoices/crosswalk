#!/bin/sh

set -e

WORKSPACE_NAME="$1"
DARKLUA_CONFIG="$2"
BUILD_OUTPUT="$3"
ROBLOX_NAME="$4"
ARTIFACT_NAME="$5"
CODE_OUTPUT=roblox

rm -rf $CODE_OUTPUT
mkdir -p $CODE_OUTPUT

yarn workspaces focus "$WORKSPACE_NAME" --production
yarn dlx npmluau

cp -rL node_modules "$CODE_OUTPUT"/node_modules

./scripts/remove-tests.sh "$CODE_OUTPUT"/node_modules

mkdir -p $CODE_OUTPUT/rojo

ASSET_PROJECT="$CODE_OUTPUT"/rojo/asset.project.json
ENTRY_POINT=entry-point.lua
FULL_ENTRY_POINT="$CODE_OUTPUT"/"$ENTRY_POINT"

echo "local module = require(\"@pkg/$WORKSPACE_NAME\")" > "$FULL_ENTRY_POINT"
tail -n +2 "$CODE_OUTPUT"/node_modules/.luau-aliases/"$WORKSPACE_NAME".luau >> "$FULL_ENTRY_POINT"

echo "{" > "$ASSET_PROJECT"
echo "  \"name\": \"$ROBLOX_NAME\"," >> "$ASSET_PROJECT"
echo "  \"tree\": {" >> "$ASSET_PROJECT"
echo "    \"\$path\": \"../$ENTRY_POINT\"," >> "$ASSET_PROJECT"
echo "    \"node_modules\": {" >> "$ASSET_PROJECT"
echo "      \"\$path\": \"../node_modules\"" >> "$ASSET_PROJECT"
echo "    }" >> "$ASSET_PROJECT"
echo "  }" >> "$ASSET_PROJECT"
echo "}" >> "$ASSET_PROJECT"

rojo sourcemap "$ASSET_PROJECT" -o $CODE_OUTPUT/rojo/sourcemap.json
cp $DARKLUA_CONFIG $CODE_OUTPUT/$DARKLUA_CONFIG

darklua process --config $CODE_OUTPUT/$DARKLUA_CONFIG $FULL_ENTRY_POINT $FULL_ENTRY_POINT
darklua process --config $CODE_OUTPUT/$DARKLUA_CONFIG $CODE_OUTPUT/node_modules $CODE_OUTPUT/node_modules

mkdir -p "$BUILD_OUTPUT"

rm -f "$BUILD_OUTPUT"/"$ARTIFACT_NAME"

rojo build "$ASSET_PROJECT" -o "$BUILD_OUTPUT"/"$ARTIFACT_NAME"
