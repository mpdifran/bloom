#!/bin/bash
#
# Renders the App Store screenshot views to PNGs, one folder per language.
#
# Xcode's preview canvas can't be scripted, so this runs ScreenshotCaptureTests instead - it hosts
# the same views the previews show and writes them to disk.
#
# Language is forced per run with -testLanguage rather than per preview: the app's strings resolve
# against the process's preferred localization, so anything short of a separate run per language
# gives translated fixtures inside an English UI.
#
# Usage: Apps/Bloom/Scripts/capture-screenshots.sh [output-directory]

set -uo pipefail   # not -e: a failed language should not abort the sweep

OUTPUT_DIR="${1:-$HOME/Desktop/BloomScreenshots}"
DEVICE="${SCREENSHOT_DEVICE:-iPhone 17 Pro}"
# language:region. -testLanguage alone leaves the region at en_US, so a German run rendered
# German words with a US 12-hour clock ("2 AM") and US unit abbreviations ("6h 57min"). The
# region drives dates, times, numbers and units, so it has to match the market.
LOCALES=(en:US fr:FR fr-CA:CA de:DE nl:NL es:ES)

WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$WORKSPACE_DIR"

# Isolated from Xcode's DerivedData: a concurrent build in the same location fails with
# "database is locked".
DERIVED_DATA="${SCREENSHOT_DERIVED_DATA:-$WORKSPACE_DIR/.screenshot-build}"

# Where ScreenshotCaptureTests writes before we move the files to $OUTPUT_DIR. Must match the
# fallback in that test.
STAGING="$WORKSPACE_DIR/.screenshots"

mkdir -p "$OUTPUT_DIR"
echo "Output:  $OUTPUT_DIR"
echo "Device:  $DEVICE"
echo

for entry in "${LOCALES[@]}"; do
  language="${entry%%:*}"
  region="${entry##*:}"
  echo "==> $language ($region)"

  if xcodebuild test \
    -workspace Bloom.xcworkspace \
    -scheme Bloom \
    -destination "platform=iOS Simulator,name=$DEVICE" \
    -derivedDataPath "$DERIVED_DATA" \
    -only-testing:BloomTests/ScreenshotCaptureTests \
    -testLanguage "$language" \
    -testRegion "$region" \
    TEST_RUNNER_SCREENSHOT_OUTPUT_DIR="$OUTPUT_DIR" \
    -quiet > "/tmp/screenshots-$language.log" 2>&1
  then
    # The test stages into <repo>/.screenshots/<language> and we move the files from there.
    # Passing the destination through TEST_RUNNER_SCREENSHOT_OUTPUT_DIR does not work: xcodebuild
    # only forwards those into a UI test runner, and this is a unit test hosted in the app, so the
    # variable never arrives and the test falls back to its staging directory regardless.
    if [ -d "$STAGING/$language" ]; then
      mkdir -p "$OUTPUT_DIR/$language"
      mv -f "$STAGING/$language"/*.png "$OUTPUT_DIR/$language/" 2>/dev/null || true
      rmdir "$STAGING/$language" 2>/dev/null || true
    fi

    count=$(find "$OUTPUT_DIR/$language" -name '*.png' 2>/dev/null | wc -l | tr -d ' ' || true)
    echo "    $count screenshots"
  else
    echo "    FAILED - see /tmp/screenshots-$language.log"
    grep -E "error:|Failing tests" "/tmp/screenshots-$language.log" | head -5 || true
  fi
done

echo
echo "Done. $(find "$OUTPUT_DIR" -name '*.png' 2>/dev/null | wc -l | tr -d ' ' || echo 0) screenshots in $OUTPUT_DIR"
