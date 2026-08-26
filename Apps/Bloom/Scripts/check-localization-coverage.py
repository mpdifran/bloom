#!/usr/bin/env python3
"""Fail CI when a shipped string has no translation in one of the App Store languages.

Xcode never fails a build over an untranslated string - it silently falls back to the development
language, so English leaks into a localized screen and nothing reports it. That is how "Daily Goal"
and "4,000 steps" shipped into the German, Spanish, French and Dutch App Store screenshots.

fr-CA is the sharpest edge here. Declaring it in a catalog opts the app out of the fr match it would
otherwise get for free, and every key missing from fr-CA falls back to English rather than to French
- so a partial fr-CA localization is strictly worse than none. Run sync-fr-ca.py to fill it.

Every shipped string must be translated into every language. There is no allowance and no backlog
file - a single missing translation fails the run.

It did not start this way. A localization-baseline.json once recorded 905 accepted gaps so the check
could block new drift while the backlog was worked down, and the effect was a gate that reported OK
while permission prompts, nutrient names and half the developer menu were still English. The backlog
is cleared, so the allowance is gone with it.

Strings that are pure format glue - "%@", "-", " • " - carry shouldTranslate=false in the catalog and
are skipped here. That flag is the only way to exempt a string, and it lives next to the string
rather than in a list far away from it.

This is not wired into the Xcode build: failing a local build the moment someone types a new
Text("...") would be miserable. It runs in CI, where the branch is meant to be shippable.

  ./check-localization-coverage.py                  demand full coverage

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



def main():
    arguments = sys.argv[1:]

    # Every catalog, not just Localizable: the permission prompts live in InfoPlist.xcstrings and
    # went unchecked for as long as this only looked at one filename.
    paths = sorted(glob.glob("*/*.xcstrings"))
    if not paths:
        print("warning: no String Catalogs found")
        return 0

    gaps, shipped = find_gaps(paths)

    if gaps:
        for path in sorted(gaps):
            for language in sorted(gaps[path]):
                keys = gaps[path][language]
                print(f"{path} [{language}]: {len(keys)} untranslated")
                for key in sorted(keys)[:10]:
                    print(f"    {key!r}")
                if len(keys) > 10:
                    print(f"    ... and {len(keys) - 10} more")
        total = sum(len(keys) for langs in gaps.values() for keys in langs.values())
        print(f"\nFAIL: {total} untranslated string(s) across {shipped} shipped strings.")
        print("Translate them, or mark pure format glue with shouldTranslate=false in the catalog.")
        return 1

    print(f"Localization coverage OK: {shipped} shipped strings, all {len(LANGUAGES)} languages")
    return 0


if __name__ == "__main__":
    sys.exit(main())
