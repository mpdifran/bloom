#!/bin/sh

# Install SwiftLint using Homebrew
if ! which swiftlint > /dev/null; then
    echo "SwiftLint not found. Installing..."
    brew install swiftlint
fi

# Verify installation
swiftlint version

# Install Bugsnag CLI
curl -o- https://raw.githubusercontent.com/bugsnag/bugsnag-cli/main/install.sh | bash

