#!/usr/bin/env bash

if [[ "$(uname -m)" == arm64 ]]; then
    export PATH="/opt/homebrew/bin:$PATH"
fi

if which swiftlint > /dev/null; then
  swiftlint --fix && swiftlint || exit 1
else
  echo "SwiftLint not installed. Install it via Homebrew: brew install swiftlint"
  exit 1
fi
