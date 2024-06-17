#!/bin/bash

pushd ../shep/openapi

./generate-flask.sh
./generate-swift.sh

popd

# Assign arguments to variables
SOURCE_DIR="../shep/openapi/bloom-swift-api/"
DEST_DIR="./bloom-swift-api"

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Source directory does not exist: $SOURCE_DIR"
    exit 1
fi

# Create destination directory if it does not exist
mkdir -p "$DEST_DIR"

# Copy the directory
cp -r "$SOURCE_DIR"/* "$DEST_DIR"

echo "Copied API"
