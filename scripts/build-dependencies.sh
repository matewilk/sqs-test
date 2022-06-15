#!/usr/bin/env bash
set -x
set -e

ORIGINAL_DIR="$(pwd)"
LAYER_DIR=$ORIGINAL_DIR/dist/layers

# nodejs folder required by lambda layer
mkdir -p $LAYER_DIR/nodejs
cp -RL node_modules $LAYER_DIR/nodejs

cd $LAYER_DIR
zip -rmq dependency_layer.zip nodejs

cd $ORIGINAL_DIR