#!/bin/zsh
set -euxo pipefail

# Adjust these if you move things later
SRC_FILE="../Bloom/UserInterface/Components/Metal/Stripes.metal"
OUT_DIR="../Bloom/UserInterface/Components/Metal/Prebuilt"
MIN_IOS="18.0"   # pick your minimum supported iOS

# Clean output
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

# tmp dir for intermediates
TMP="$(mktemp -d)"

# Compile once for device
xcrun -sdk iphoneos metal \
  -c "$SRC_FILE" \
  -o "$TMP/Strips.ios.air" \
  -mios-version-min="$MIN_IOS" \
  -O3

xcrun -sdk iphoneos metallib \
  "$TMP/Strips.ios.air" \
  -o "$OUT_DIR/default-ios.metallib"

# Compile once for simulator
xcrun -sdk iphonesimulator metal \
  -c "$SRC_FILE" \
  -o "$TMP/Strips.sim.air" \
  -mios-version-min="$MIN_IOS" \
  -O3

xcrun -sdk iphonesimulator metallib \
  "$TMP/Strips.sim.air" \
  -o "$OUT_DIR/default-sim.metallib"

rm -rf "$TMP"

echo "Built:"
ls -l "$OUT_DIR"/default-*.metallib