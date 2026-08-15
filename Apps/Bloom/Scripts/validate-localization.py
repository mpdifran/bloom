#!/usr/bin/env python3
"""Fail the build when a translation's format placeholders don't match its source string.

A translation that drops a placeholder, adds one, or changes its type is a crash at runtime -
String(format:) reads an argument that was never passed - and nothing else in the build catches it.
Xcode validates that a catalog parses; it does not compare placeholders across languages.

Also enforces positional placeholders (%1$@) whenever a string has two or more, because word order
changes between languages and non-positional placeholders can't be reordered by a translator.

Run with no arguments from Apps/Bloom, or pass catalog paths explicitly.
"""
import glob
import json
import re
import sys
from collections import Counter

# %@, %lld, %.1f, and positional forms like %1$@
PLACEHOLDER = re.compile(r"%(?:(\d+)\$)?[-+ #0]*[\d.]*(@|lld|ld|d|f|u|s)")


def signature(text):
    """Multiset of placeholder types, ignoring position markers and literal %%."""
    return Counter(match.group(2) for match in PLACEHOLDER.finditer(text.replace("%%", "")))


def is_positional(text):
    matches = list(PLACEHOLDER.finditer(text.replace("%%", "")))
    if len(matches) < 2:
        return True
    return all(match.group(1) for match in matches)


def main():
    paths = sys.argv[1:] or sorted(glob.glob("*/Localizable.xcstrings"))
    if not paths:
        print("warning: no String Catalogs found")
        return 0

    problems = []
    checked = 0

    for path in paths:
        with open(path) as handle:
            catalog = json.load(handle)

        for key, entry in catalog.get("strings", {}).items():
            localizations = entry.get("localizations", {})

            # Most keys are the English text itself, so the key carries the placeholders. Keys that
            # are identifiers instead - the loc-keys the backend sends via APNs - carry none, and
            # their English localization is the real source string.
            english = localizations.get("en", {}).get("stringUnit", {}).get("value")
            source = signature(english if english is not None else key)

            for language, localization in localizations.items():
                if language == "en":
                    continue
                value = localization.get("stringUnit", {}).get("value")
                if value is None:
                    continue
                checked += 1

                translated = signature(value)
                if translated != source:
                    problems.append(
                        f'{path}: error: [{language}] placeholder mismatch for "{key}": '
                        f"source has {dict(source)}, translation has {dict(translated)}"
                    )
                elif sum(source.values()) >= 2 and not is_positional(value):
                    problems.append(
                        f'{path}: error: [{language}] "{key}" has multiple placeholders, so the '
                        "translation must use positional forms (%1$@, %2$@) to allow reordering"
                    )

    for problem in problems:
        print(problem)

    if problems:
        print(f"{len(problems)} localization problem(s) across {checked} translations")
        return 1

    print(f"Localization OK: {checked} translations checked")
    return 0


if __name__ == "__main__":
    sys.exit(main())
