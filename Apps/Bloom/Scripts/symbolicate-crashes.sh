#!/usr/bin/env bash
#
# symbolicate-crashes.sh — Symbolicate the crash reports waiting on the backend.
#
# Pulls every unsymbolicated crash, resolves its frames with atos, and sends the result back.
# Reports carry each loaded binary's UUID and load address, so a dSYM is matched by UUID rather
# than guessed at from a build number, and atos is given -l so the addresses actually resolve.
# Ported from AirChat's symbolicate-pending.sh.
#
# Two ways to find symbols:
#
#   --local <dir>   Search a directory for dSYMs or binaries and match them by UUID. This is how
#                   you symbolicate a crash from a build still sitting in DerivedData - a Debug
#                   build has no .dSYM at all, its DWARF is inside Bloom.debug.dylib.
#   (default)       Download each dSYM zip from the signed URL the backend hands out, which is
#                   what ci_scripts/ci_post_xcodebuild.sh uploads for every archived build.
#
# A report where nothing resolved is left for a later run - its build's symbols may simply not be
# registered yet - unless it's older than GIVE_UP_DAYS, when it's sent as-is so it stops coming
# back.
#
# Usage:
#   Apps/Bloom/Scripts/symbolicate-crashes.sh [--app bloom|bloom-watch] [--local <dir>] [--limit N] [--dry-run]
#
# Environment:
#   CRASH_ADMIN_SECRET  Admin bearer token. Read from Heroku config if unset.
#   CRASH_API_BASE      Defaults to https://api.trybloom.app.
#
# Requires: curl, jq, atos, dwarfdump.

set -euo pipefail

BASE="${CRASH_API_BASE:-https://api.trybloom.app}"
HEROKU_APP="${HEROKU_APP:-bloom-api}"
CACHE="${TMPDIR:-/tmp}/bloom-dsyms"
GIVE_UP_DAYS=3

APPS=(bloom bloom-watch)
LOCAL_DIR=""
LIMIT=25
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app) APPS=("$2"); shift 2 ;;
    --local) LOCAL_DIR="$2"; shift 2 ;;
    --limit) LIMIT="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "${CRASH_ADMIN_SECRET:-}" ]] && command -v heroku >/dev/null 2>&1; then
  CRASH_ADMIN_SECRET="$(heroku config:get CRASH_ADMIN_SECRET -a "$HEROKU_APP" 2>/dev/null)"
fi
if [[ -z "${CRASH_ADMIN_SECRET:-}" ]]; then
  echo "CRASH_ADMIN_SECRET is not set and could not be read from Heroku." >&2
  exit 1
fi

mkdir -p "$CACHE"

# ── Index whatever symbols we can reach, by UUID ────────────────────────────────────────────────
#
# Both a .dSYM bundle and a plain binary answer dwarfdump --uuid, and in a Debug build only the
# binary exists - so both are indexed the same way.

INDEX="$CACHE/index.txt"
: > "$INDEX"

index_symbols_in() {
  local root="$1"

  while IFS= read -r candidate; do
    [[ -f "$candidate" ]] || continue

    dwarfdump --uuid "$candidate" 2>/dev/null | while read -r _ uuid arch _; do
      [[ -n "${uuid:-}" ]] || continue
      # dwarfdump prints "UUID: <uuid> (<arch>) <path>"; normalise to the backend's form.
      local normalised="${uuid//-/}"
      echo "${normalised}|${arch//[()]/}|${candidate}" >> "$INDEX"
    done
  done < <(
    find "$root" \( -name "*.dSYM" -o -perm +111 -type f \) -maxdepth 6 2>/dev/null | while read -r item; do
      if [[ -d "$item" ]]; then
        find "$item/Contents/Resources/DWARF" -type f 2>/dev/null
      else
        file "$item" 2>/dev/null | grep -q "Mach-O" && echo "$item"
      fi
    done
  )
}

if [[ -n "$LOCAL_DIR" ]]; then
  echo "Indexing symbols under $LOCAL_DIR ..."
  index_symbols_in "$LOCAL_DIR"
  echo "Indexed $(wc -l < "$INDEX" | tr -d ' ') binaries."
fi

symbol_file_for_uuid() {
  local uuid="$1"
  # No match is the normal case - most frames are system libraries we have no symbols for - so
  # the failure is swallowed rather than ending the run under `set -o pipefail`.
  grep -i "^${uuid}|" "$INDEX" 2>/dev/null | head -1 | cut -d'|' -f3 || true
}

download_dsym() {
  local url="$1"
  # The URL is signed afresh on every call, so cache on the object's name rather than the URL. A
  # build's binaries all share one zip; this downloads it once.
  local name
  name="$(basename "${url%%\?*}")"
  local target="$CACHE/zips/${name%.zip}"

  [[ -d "$target" ]] && return

  mkdir -p "$target"
  if curl -sSfL -o "$target/dsyms.zip" "$url"; then
    (cd "$target" && unzip -qo dsyms.zip 2>/dev/null) || true
    index_symbols_in "$target"
  else
    echo "  could not download $name" >&2
    rm -rf "$target"
  fi
}

# Symbols already downloaded by an earlier run are still valid; index them up front.
if [[ -z "$LOCAL_DIR" && -d "$CACHE/zips" ]]; then
  index_symbols_in "$CACHE/zips"
fi

# The frame rows the loop below consumes.
#
# Two report shapes come through here. A signal-handler report carries a real, ASLR-slid
# `loadAddress` per image and an absolute `.address` per frame - atos wants that pair as-is.
# A MetricKit report carries neither: Apple's diagnostic payload never exposes the real load
# address (every `binaryImages[].loadAddress` reads back "0x0"), and each frame gives only
# `.offset`, measured from the image's own start. For that shape the dSYM's own `__TEXT` vmaddr
# (registered per-UUID by ci_post_xcodebuild.sh, alongside `textVMAddr`) stands in for the load
# address, and the frame's resolvable address is that vmaddr plus the offset - the arithmetic
# below does that in the shell, since jq has no hex math.
#
# Missing values fall back to "-", not "": tab is "IFS whitespace" to bash even when IFS is set
# to nothing but a tab, so `read` silently collapses two adjacent tabs (an empty field) instead
# of preserving it - every column after the first empty one then shifts left by one. A frame
# with no `.address` (every MetricKit frame) hit this on every single row.
FRAME_QUERY='
  ([.report.binaryImages[]? | {key: .uuid, value: {load: .loadAddress, arch: .arch}}] | from_entries) as $images
  | ([.dsyms[]? | {key: .uuid, value: (.textVMAddr // "0x0")}] | from_entries) as $textVMAddrs
  | .report.frames[]?
  | [ (.index|tostring),
      (.imageUUID // "-"),
      (.address // "-"),
      (.offset // "-"),
      (.imageName // "???"),
      ($images[(.imageUUID // "")].load // "-"),
      ($images[(.imageUUID // "")].arch // "arm64"),
      ($textVMAddrs[(.imageUUID // "")] // "0x0") ]
  | @tsv
'

# ── Work through the backlog ────────────────────────────────────────────────────────────────────

for APP in "${APPS[@]}"; do

REPORTS="$(curl -sf -H "Authorization: Bearer $CRASH_ADMIN_SECRET" \
  "$BASE/v1/admin/apps/$APP/crashes/unsymbolicated?limit=$LIMIT")"

COUNT="$(echo "$REPORTS" | jq 'length')"
echo "$APP: $COUNT report(s) waiting."
[[ "$COUNT" -eq 0 ]] && continue

for index in $(seq 0 $((COUNT - 1))); do
  ENTRY="$(echo "$REPORTS" | jq ".[$index]")"
  REPORT="$(echo "$ENTRY" | jq '.report')"
  ID="$(echo "$REPORT" | jq -r '.id')"
  EXCEPTION="$(echo "$REPORT" | jq -r '.exceptionType')"
  BUILD="$(echo "$REPORT" | jq -r '.buildNumber')"

  echo "→ $ID ($EXCEPTION, build $BUILD)"

  # In download mode, fetch the symbols this report's own images need.
  if [[ -z "$LOCAL_DIR" ]]; then
    while IFS= read -r url; do
      [[ -n "$url" ]] && download_dsym "$url"
    done < <(echo "$ENTRY" | jq -r '[.dsyms[]?.downloadURL] | unique | .[]')
  fi

  # Resolve every frame we have symbols for; leave the rest as they were.
  #
  # jq flattens each frame to a row first - index, uuid, absolute address (signal-handler
  # reports), offset (MetricKit reports), image name, that image's load address, its arch, and
  # its dSYM's own __TEXT vmaddr - so the shell below only has to pick the right pair and call
  # atos.
  FRAMES_FILE="$CACHE/frames.tsv"
  jq -r "$FRAME_QUERY" <<< "$ENTRY" > "$FRAMES_FILE"

  TRACE_FILE="$CACHE/trace.txt"
  : > "$TRACE_FILE"

  while IFS=$'\t' read -r idx uuid address offset image_name load arch text_vmaddr; do
    [[ "$uuid" == "-" ]] && uuid=""
    [[ "$address" == "-" ]] && address=""
    [[ "$offset" == "-" ]] && offset=""
    [[ "$load" == "-" ]] && load=""

    symbols=""
    resolve_address="$address"
    resolve_load="$load"

    # No real address or load address (MetricKit) - derive both from the offset and the dSYM's
    # own text segment base, which is exactly what that offset was measured against. The
    # arithmetic expansion runs in its own `if`, not inline in an assignment: a malformed operand
    # makes bash raise a fatal error at expansion time, before any `|| true` on the surrounding
    # command would get a chance to catch it.
    if [[ -z "$resolve_address" && -n "$offset" ]]; then
      computed_address=""
      if computed_address=$(( text_vmaddr + offset )) 2>/dev/null; then
        resolve_address="$(printf '0x%x' "$computed_address")"
        resolve_load="$text_vmaddr"
      fi
    fi

    if [[ -n "$uuid" && -n "$resolve_address" && -n "$resolve_load" ]]; then
      binary="$(symbol_file_for_uuid "$uuid")"
      if [[ -n "$binary" ]]; then
        # -l is the whole point: without the load address every frame resolves against the
        # dSYM's own base and comes out wrong rather than missing, which is worse. `|| true`
        # because `atos` exits non-zero on a frame it can't place - not a script-ending problem
        # under `set -o pipefail`, just an unresolved frame like any other.
        symbols="$(atos -o "$binary" -arch "${arch:-arm64}" -l "$resolve_load" "$resolve_address" 2>/dev/null | head -1)" || true
      fi
    fi

    original="${address:-$offset}"
    if [[ -n "$symbols" && "$symbols" != "$resolve_address" ]]; then
      printf '%-4s%-32s%s\n' "$idx" "$image_name" "$symbols" >> "$TRACE_FILE"
    else
      printf '%-4s%-32s%s\n' "$idx" "$image_name" "$original" >> "$TRACE_FILE"
    fi
  done < "$FRAMES_FILE"

  TRACE="$(cat "$TRACE_FILE")"

  RESOLVED="$(grep -c " (in " "$TRACE_FILE" || true)"
  echo "   resolved $RESOLVED frame(s)"

  if [[ "$RESOLVED" -eq 0 ]]; then
    CREATED="$(echo "$REPORT" | jq -r '.createdAt // empty')"
    AGE_DAYS=0
    if [[ -n "$CREATED" ]]; then
      # "2026-09-29T21:00:00Z", with or without fractional seconds.
      CREATED_BASE="${CREATED%Z}"
      CREATED_BASE="${CREATED_BASE%%.*}"
      if CREATED_EPOCH="$(date -j -u -f "%Y-%m-%dT%H:%M:%S" "$CREATED_BASE" +%s 2>/dev/null)"; then
        AGE_DAYS=$(( ($(date -u +%s) - CREATED_EPOCH) / 86400 ))
      fi
    fi
    if [[ "$AGE_DAYS" -lt "$GIVE_UP_DAYS" ]]; then
      echo "   nothing resolved - leaving it for a later run"
      continue
    fi
    echo "   nothing resolved after $AGE_DAYS days - sending as-is"
  fi

  if $DRY_RUN; then
    echo "$TRACE" | head -12
    continue
  fi

  BODY="$(jq -n --arg trace "$TRACE" '{symbolicatedTrace: $trace}')"
  if curl -sf -X PUT -H "Content-Type: application/json" \
      -H "Authorization: Bearer $CRASH_ADMIN_SECRET" \
      -d "$BODY" "$BASE/v1/admin/apps/$APP/crashes/$ID/symbolicate" > /dev/null; then
    echo "   sent"
  else
    echo "   failed to send" >&2
  fi
done

done
