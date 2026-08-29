#!/usr/bin/env bash

# Two checks the compiler cannot do, run as a build phase so they fail the build:
#
#   1. Every translation's format placeholders match its source string. A mismatch is a runtime
#      crash in String(format:), and nothing else compares placeholders across languages.
#   2. No string literal reaches a Text through a plain String property. Those never get extracted,
#      so they render in English in every language while the coverage gate still reports 100%.

set -euo pipefail

cd "${SRCROOT}"

if ! command -v python3 > /dev/null; then
  echo "warning: python3 not found, skipping localization validation"
  exit 0
fi

python3 Scripts/validate-localization.py
python3 Scripts/check-unlocalized-literals.py
