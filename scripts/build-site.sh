#!/bin/sh

set -e

./scripts/build.sh

mkdir -p ./docs/releases
rm -rf ./docs/releases/main

cp -rf ./build ./docs/releases/main

mkdocs build
