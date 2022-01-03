#!/bin/sh

set -ex

./scripts/build-assets.sh

mkdir -p ./docs/releases
rm -rf ./docs/releases/master

cp -rf ./build ./docs/releases/master

mkdocs build
