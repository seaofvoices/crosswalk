#!/bin/sh

set -ex

./scripts/build-assets.sh

mkdir -p ./docs/releases
rm -rf ./docs/releases/main

cp -rf ./build ./docs/releases/main

mkdocs build
