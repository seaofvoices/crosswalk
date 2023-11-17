#!/bin/sh

set -e

DARKLUA_CONFIG=$1
ROJO_CONFIG=$2
BUILD_OUTPUT=$3
ARTIFACT_NAME=$4
CODE_OUTPUT=roblox/$DARKLUA_CONFIG

yarn install
yarn prepare

rm -rf $CODE_OUTPUT
mkdir -p $CODE_OUTPUT

cp -r node_modules $CODE_OUTPUT/node_modules

if [ -z ${TESTS+x} ]; then
    echo "remove test related files..."
    find $CODE_OUTPUT/node_modules -name 'tests-utils' -type d -exec rm -r {} +
    find $CODE_OUTPUT/node_modules -name 'crosswalk-test-utils' -type d -exec rm -r {} +
    find $CODE_OUTPUT/node_modules -name 'crosswalk-test-utils.luau' -type f -exec rm -r {} +
    find $CODE_OUTPUT/node_modules -name '*.spec.lua' -type f -exec rm -r {} +
else
    mkdir -p $CODE_OUTPUT/modules
    cp -r modules/testez $CODE_OUTPUT/modules
fi

mkdir -p $CODE_OUTPUT/rojo

rojo sourcemap rojo/$ROJO_CONFIG -o $CODE_OUTPUT/rojo/sourcemap.json
cp rojo/$ROJO_CONFIG $CODE_OUTPUT/rojo
cp $DARKLUA_CONFIG $CODE_OUTPUT/$DARKLUA_CONFIG

darklua process --config $CODE_OUTPUT/$DARKLUA_CONFIG $CODE_OUTPUT/node_modules $CODE_OUTPUT/node_modules

mkdir -p $BUILD_OUTPUT

rm -f $BUILD_OUTPUT/$ARTIFACT_NAME

cp -r test-place $CODE_OUTPUT

rojo build $CODE_OUTPUT/rojo/$ROJO_CONFIG -o $BUILD_OUTPUT/$ARTIFACT_NAME
