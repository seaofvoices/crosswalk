#!/bin/sh

set -ex

lune build-assets

mkdir -p ./docs/releases
rm -rf ./docs/releases/main

cp -rf ./build ./docs/releases/main

mkdocs build
