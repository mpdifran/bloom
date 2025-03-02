#!/bin/sh

# Install SwiftLint using Homebrew
if ! which swiftlint > /dev/null; then
    echo "SwiftLint not found. Installing..."
    brew install swiftlint
fi

# Verify installation
swiftlint version
