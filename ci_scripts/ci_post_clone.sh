#!/bin/zsh
set -euxo pipefail

# --- Ensure Homebrew is on PATH (if present) ---
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# --- SwiftLint: intentionally not installed on Xcode Cloud ---
# The build phase (Scripts/swiftlint.sh) skips linting when CI_XCODE_CLOUD=TRUE,
# so there's no need to install SwiftLint here. Linting runs locally / on PRs.

# --- Metal toolchain ---
if ! xcrun -f metal >/dev/null 2>&1; then
  echo "Installing Metal Toolchain (missing)…"
  xcodebuild -downloadComponent MetalToolchain || {
    echo "First attempt failed, retrying in 10s…"
    sleep 10
    xcodebuild -downloadComponent MetalToolchain
  }

  # Sanity check
  if ! xcrun -f metal >/dev/null 2>&1; then
    echo "ERROR: 'metal' compiler still not available after install."
    xcodebuild -showBuildSettings || true
    exit 1
  fi
else
  echo "Metal Toolchain already present."
fi

echo "Metal Toolchain OK."
xcrun metal -v || true
