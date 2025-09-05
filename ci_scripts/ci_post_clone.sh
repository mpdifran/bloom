#!/bin/zsh
set -euxo pipefail

# --- Ensure Homebrew is on PATH (if present) ---
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# --- SwiftLint ---
if ! command -v swiftlint >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    echo "SwiftLint not found. Installing via Homebrew…"
    brew install swiftlint
  else
    echo "WARNING: Homebrew not available; skipping SwiftLint install."
  fi
fi

if command -v swiftlint >/dev/null 2>&1; then
  swiftlint version
else
  echo "NOTE: swiftlint still not found; continuing without lint."
fi

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
