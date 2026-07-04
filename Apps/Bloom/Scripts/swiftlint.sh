#!/usr/bin/env bash

# Skip on Xcode Cloud — SwiftLint's SourceKitten can't load the image's sourcekitd.
# Linting runs locally and on PRs instead.
if [ "$CI_XCODE_CLOUD" = "TRUE" ]; then
  echo "Xcode Cloud detected. Skipping SwiftLint."
  exit 0
fi

if [[ "$(uname -m)" == arm64 ]]; then
    export PATH="/opt/homebrew/bin:$PATH"
fi

if which swiftlint > /dev/null; then
  swiftlint --fix && swiftlint || exit 1
else
  echo "SwiftLint not installed. Install it via Homebrew: brew install swiftlint"
  exit 1
fi
