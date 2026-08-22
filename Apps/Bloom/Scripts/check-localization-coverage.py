#!/usr/bin/env python3
"""Fail CI when a shipped string has no translation in one of the App Store languages.

Xcode never fails a build over an untranslated string - it silently falls back to the development
language, so English leaks into a localized screen and nothing reports it. That is how "Daily Goal"
and "4,000 steps" shipped into the German, Spanish, French and Dutch App Store screenshots.

fr-CA is the sharpest edge here. Declaring it in a catalog opts the app out of the fr match it would
otherwise get for free, and every key missing from fr-CA falls back to English rather than to French
- so a partial fr-CA localization is strictly worse than none. Run sync-fr-ca.py to fill it.

Known gaps live in localization-baseline.json so this can block regressions today while the existing
backlog is worked down. A string missing from the baseline fails the run; a baseline entry that has
since been translated is reported so the baseline can shrink. Nothing is ever added automatically -
run --write-baseline deliberately.

This is not wired into the Xcode build: failing a local build the moment someone types a new
Text("...") would be miserable. It runs in CI, where the branch is meant to be shippable.

  ./check-localization-coverage.py                  check against the baseline
  ./check-localization-coverage.py --strict         ignore the baseline, demand full coverage
  ./check-localization-coverage.py --write-baseline record today's gaps as accepted

Run with no arguments from Apps/Bloom.
"""
import glob
import json
import os
import sys
from collections import defaultdict

# The languages the app ships on the App Store. Listed rather than derived from the catalogs so that
# a catalog missing a language entirely fails here instead of looking complete.
LANGUAGES = ["de", "es", "fr", "fr-CA", "nl"]

BASELINE_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "localization-baseline.json")

# Gaps per language are listed up to this many, then summarized.
MAX_LISTED = 10


def is_shipped(key, entry):
    """Whether this string reaches a user and therefore needs translating."""
    if not key.strip():
        return False
    if not entry.get("shouldTranslate", True):
        return False
    # Xcode marks a key stale once no source file references it. Dead weight in the catalog, not a
    # hole in the localization.
    return entry.get("extractionState") != "stale"


def find_gaps(paths):
    """Map of catalog path -> language -> sorted keys with no translation."""
    gaps = defaultdict(lambda: defaultdict(list))
    shipped = 0

    for path in paths:
        with open(path, encoding="utf-8") as handle:
            catalog = json.load(handle)

        for key, entry in catalog.get("strings", {}).items():
            if not is_shipped(key, entry):
                continue
            shipped += 1
            localizations = entry.get("localizations", {})
            for language in LANGUAGES:
                if language not in localizations:
                    gaps[path][language].append(key)

    return {p: {lang: sorted(keys) for lang, keys in langs.items()} for p, langs in gaps.items()}, shipped


def load_baseline():
    if not os.path.exists(BASELINE_PATH):
        return {}
    with open(BASELINE_PATH, encoding="utf-8") as handle:
        return json.load(handle)


def main():
    arguments = sys.argv[1:]
    strict = "--strict" in arguments
    writing = "--write-baseline" in arguments

    paths = sorted(glob.glob("*/Localizable.xcstrings"))
    if not paths:
        print("warning: no String Catalogs found")
        return 0

    gaps, shipped = find_gaps(paths)

    if writing:
        with open(BASELINE_PATH, "w", encoding="utf-8") as handle:
            json.dump(gaps, handle, indent=2, ensure_ascii=False, sort_keys=True)
            handle.write("\n")
        total = sum(len(keys) for langs in gaps.values() for keys in langs.values())
        print(f"Wrote baseline: {total} accepted gap(s) across {shipped} shipped strings")
        print(f"  {BASELINE_PATH}")
        return 0

    baseline = {} if strict else load_baseline()

    new_gaps = 0
    accepted = 0

    for path in sorted(gaps):
        for language in LANGUAGES:
            keys = gaps[path].get(language, [])
            if not keys:
                continue
            known = set(baseline.get(path, {}).get(language, []))
            fresh = [key for key in keys if key not in known]
            accepted += len(keys) - len(fresh)
            if not fresh:
                continue
            new_gaps += len(fresh)
            print(f"{path}: error: [{language}] {len(fresh)} untranslated string(s)")
            for key in fresh[:MAX_LISTED]:
                print(f"    {key!r}")
            if len(fresh) > MAX_LISTED:
                print(f"    ... and {len(fresh) - MAX_LISTED} more")

    # A baseline entry that now has a translation should be dropped, so the backlog only shrinks.
    fixed = 0
    for path, languages in baseline.items():
        for language, keys in languages.items():
            still_missing = set(gaps.get(path, {}).get(language, []))
            fixed += len([key for key in keys if key not in still_missing])

    if new_gaps:
        print(f"\n{new_gaps} newly untranslated string(s) across {shipped} shipped strings")
        print("Translate them in Xcode, or run Scripts/sync-fr-ca.py if the gap is fr-CA.")
        print("If a string genuinely needs no translation, tick \"Don't Translate\" on it in Xcode.")
        return 1

    print(f"Localization coverage OK: {shipped} shipped strings, all {len(LANGUAGES)} languages")
    if accepted:
        print(f"  {accepted} known gap(s) still accepted by localization-baseline.json")
    if fixed:
        print(f"  {fixed} baseline gap(s) now translated - re-run with --write-baseline to shrink it")
    return 0


if __name__ == "__main__":
    sys.exit(main())
