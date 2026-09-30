#!/usr/bin/env bash

#  ci_post_xcodebuild.sh
#
#  Created by Mark DiFranco on 2024-03-26.
#
#  Publishes an archive's debug symbols. Xcode Cloud runs this after every action; only the archive
#  action sets CI_ARCHIVE_PATH, so everything else exits immediately.
#
#  Bloom: zips every dSYM in the archive (the app, its frameworks, its extensions and the embedded
#  watch app), uploads the zip to the backend's S3 bucket, and registers one row per (binary, arch)
#  with the backend - UUID, name, text segment vmaddr and where the zip is. A crash report names
#  the UUID of every binary it loaded, so symbolication is a lookup rather than a guess from a
#  build number. See Scripts/symbolicate-crashes.sh for the other end.
#
#  Gardener: still uploads to BugSnag.
#
#  Environment (secret variables on the Xcode Cloud workflow):
#    CRASH_ADMIN_SECRET       The backend's CRASH_ADMIN_SECRET.
#    CRASH_API_BASE           Optional. Defaults to https://api.trybloom.app.
#    BUGSNAG_API_KEY_GARDENER Gardener only.
#
#  This must stay executable (chmod +x): Xcode Cloud silently skips a script it cannot execute, and
#  that looks exactly like the script never having run.

set -euo pipefail

if [[ -z "${CI_ARCHIVE_PATH:-}" ]]; then
  echo "No archive in this action; nothing to publish."
  exit 0
fi

DSYM_DIR="$CI_ARCHIVE_PATH/dSYMs"
if [[ ! -d "$DSYM_DIR" ]]; then
  echo "warning: no dSYMs in the archive at $DSYM_DIR"
  exit 0
fi

# ── Gardener ─────────────────────────────────────────────────────────────────────────────────────

if [[ "${CI_BUNDLE_ID:-}" == "com.lotus-labs.gardener" ]]; then
  if [[ -n "${BUGSNAG_API_KEY_GARDENER:-}" ]]; then
    echo "App is Gardener. Uploading dSYMs to BugSnag."
    pushd "$DSYM_DIR" > /dev/null
    curl --http1.1 https://upload.bugsnag.com/ \
      -F apiKey="$BUGSNAG_API_KEY_GARDENER" \
      -F dsym=@Gardener.app.dSYM/Contents/Resources/DWARF/Gardener \
      -F projectRoot=./
    popd > /dev/null
  else
    echo "No BugSnag API key configured for Gardener. Skipping dSYM upload."
  fi
  exit 0
fi

if [[ "${CI_BUNDLE_ID:-}" != "com.lotus-labs.bloom" ]]; then
  echo "Not a Bloom archive ($CI_BUNDLE_ID); nothing to publish."
  exit 0
fi

# ── Bloom ────────────────────────────────────────────────────────────────────────────────────────

if [[ -z "${CRASH_ADMIN_SECRET:-}" ]]; then
  # A missing secret must not fail the build: the archive is still good, it just has no symbols
  # published. Loud, but not fatal.
  echo "warning: CRASH_ADMIN_SECRET is unset - skipping dSYM publication."
  exit 0
fi

API_BASE="${CRASH_API_BASE:-https://api.trybloom.app}"
BUILD_NUMBER="${CI_BUILD_NUMBER:-0}"

# Xcode Cloud has no variable for the marketing version, so read it out of the archived app.
APP_PLIST="$(ls -d "$CI_ARCHIVE_PATH"/Products/Applications/*.app 2>/dev/null | head -1)/Info.plist"
if [[ -f "$APP_PLIST" ]]; then
  MARKETING_VERSION="$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$APP_PLIST" 2>/dev/null || echo "unknown")"
else
  MARKETING_VERSION="unknown"
fi

WORK="${TMPDIR:-/tmp}/bloom-dsyms"
mkdir -p "$WORK"
ZIP_NAME="Bloom-${MARKETING_VERSION}-${BUILD_NUMBER}.dSYMs.zip"
ZIP="$WORK/$ZIP_NAME"

echo "Zipping dSYMs from $DSYM_DIR"
rm -f "$ZIP"
ditto -c -k --keepParent "$DSYM_DIR" "$ZIP"

# Never fail the build from here on: symbols are worth publishing, not worth losing an archive over.
set +e

# ── Upload the zip ───────────────────────────────────────────────────────────────────────────────

echo "Requesting an upload URL for $ZIP_NAME"
UPLOAD="$(curl -sS -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $CRASH_ADMIN_SECRET" \
  -d "{\"filename\":\"$ZIP_NAME\"}" \
  "$API_BASE/v1/admin/apps/bloom/dsyms/upload-url")"

UPLOAD_URL="$(echo "$UPLOAD" | /usr/bin/python3 -c 'import sys,json; print(json.load(sys.stdin).get("uploadURL",""))' 2>/dev/null)"
REFERENCE="$(echo "$UPLOAD" | /usr/bin/python3 -c 'import sys,json; print(json.load(sys.stdin).get("reference",""))' 2>/dev/null)"

if [[ -z "$UPLOAD_URL" || -z "$REFERENCE" ]]; then
  echo "warning: could not get an upload URL; skipping. Response: $UPLOAD"
  exit 0
fi

echo "Uploading $(du -h "$ZIP" | cut -f1) to S3"
STATUS="$(curl -sS -o /dev/null -w "%{http_code}" -X PUT --upload-file "$ZIP" "$UPLOAD_URL")"
if [[ "$STATUS" != "200" ]]; then
  echo "warning: upload failed with HTTP $STATUS; skipping registration."
  exit 0
fi

# ── Register each binary's symbols ───────────────────────────────────────────────────────────────

echo "Indexing dSYMs"
INDEX="$WORK/index.json"

/usr/bin/python3 - "$DSYM_DIR" "$REFERENCE" "$MARKETING_VERSION" "$BUILD_NUMBER" > "$INDEX" <<'PYTHON'
import json, os, re, subprocess, sys

dsym_dir, reference, app_version, build_number = sys.argv[1:5]
rows = []

for name in os.listdir(dsym_dir):
    if not name.endswith(".dSYM"):
        continue

    dwarf_dir = os.path.join(dsym_dir, name, "Contents", "Resources", "DWARF")
    if not os.path.isdir(dwarf_dir):
        continue

    for binary_name in os.listdir(dwarf_dir):
        binary = os.path.join(dwarf_dir, binary_name)

        # "UUID: <uuid> (<arch>) <path>" - one line per architecture in the binary.
        uuids = subprocess.run(["dwarfdump", "--uuid", binary], capture_output=True, text=True).stdout
        # The text segment base, which is what a MetricKit offset is measured from.
        segments = subprocess.run(["otool", "-l", binary], capture_output=True, text=True).stdout
        vmaddr = ""
        seen_text = False
        for line in segments.splitlines():
            if "segname __TEXT" in line:
                seen_text = True
            elif seen_text and "vmaddr" in line:
                vmaddr = line.split()[-1]
                break

        for line in uuids.splitlines():
            match = re.match(r"UUID: ([0-9A-Fa-f-]+) \(([^)]+)\)", line.strip())
            if not match:
                continue

            rows.append({
                "uuid": match.group(1).replace("-", "").upper(),
                "binaryName": binary_name,
                "arch": match.group(2),
                "appVersion": app_version,
                "buildNumber": build_number,
                "downloadURL": reference,
                "textVMAddr": vmaddr,
            })

print(json.dumps({"dsyms": rows}))
PYTHON

COUNT="$(/usr/bin/python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1]))["dsyms"]))' "$INDEX")"
echo "Registering $COUNT dSYM entries"

STATUS="$(curl -sS -o /dev/null -w "%{http_code}" -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $CRASH_ADMIN_SECRET" \
  --data-binary @"$INDEX" \
  "$API_BASE/v1/admin/apps/bloom/dsyms")"

if [[ "$STATUS" != "200" ]]; then
  echo "warning: registration failed with HTTP $STATUS."
  exit 0
fi

echo "Done."
