#!/bin/sh

set -ex

./bin/build-assets.sh

mkdir -p ./docs/releases
rm -rf ./docs/releases/master

cp -rf ./build ./docs/releases/master

mkdocs build
