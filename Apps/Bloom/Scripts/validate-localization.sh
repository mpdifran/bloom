#!/usr/bin/env bash

# Checks that every translation's format placeholders match its source string. A mismatch is a
# runtime crash in String(format:), and neither the compiler nor xcstringstool compares placeholders
# across languages - so this runs as a build phase and fails the build instead.

set -euo pipefail

cd "${SRCROOT}"

if ! command -v python3 > /dev/null; then
  echo "warning: python3 not found, skipping localization validation"
  exit 0
fi

python3 Scripts/validate-localization.py
