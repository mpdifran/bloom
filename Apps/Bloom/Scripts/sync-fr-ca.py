#!/usr/bin/env python3
"""Fill fr-CA from fr, because iOS will not fall back from one to the other.

There are two different localization fallbacks and only one of them chains by language. Picking
which .lproj to use does match a parent language: a device set to fr-CA with no fr-CA.lproj in the
bundle resolves to fr.lproj. But looking a key up inside the chosen table does not chain - a missing
key goes straight to CFBundleDevelopmentRegion, which is English here.

So shipping a partial fr-CA is strictly worse than shipping none: it opts the app out of the fr
match it would otherwise get, then serves English for everything it does not itself define. The only
way to get "fr-CA falls back to fr" is to put the French strings in fr-CA, which is what this does.

fr-CA is not a cosmetic variant of fr - fr addresses the user with "vous", fr-CA with "tu". So a
blind copy would be wrong for exactly the strings that matter. Anything whose French carries a
second-person-plural form is left alone and reported for translation by hand instead.

  ./sync-fr-ca.py           fill what can be filled, report the rest
  ./sync-fr-ca.py --check   change nothing, exit non-zero if a copy is pending (for CI)

Run with no arguments from Apps/Bloom, or pass catalog paths explicitly.
"""
import glob
import json
import re
import sys

# "vous", "votre", "vos", and enclitic "-vous" as in "Êtes-vous".
VOUVOIEMENT = re.compile(r"\b(?:vous|votre|vos|vôtre)\b|-vous\b", re.IGNORECASE)

# Second-person-plural verb endings, which carry the register even with no pronoun in sight:
# "Autorisez l'accès", "Veuillez patienter". A handful of common non-verbs end in -ez too.
VERB_ENDING = re.compile(r"\b\w{3,}ez\b", re.IGNORECASE)
NOT_VERBS = {"assez", "chez", "nez", "rez"}


def is_vouvoiement(text):
    """Whether this French string addresses the user as "vous", so fr-CA needs its own wording."""
    if VOUVOIEMENT.search(text):
        return True
    return any(match.group(0).lower() not in NOT_VERBS for match in VERB_ENDING.finditer(text))


def value_of(localizations, language):
    return localizations.get(language, {}).get("stringUnit", {}).get("value")


def read(path):
    """Return the parsed catalog plus the formatting quirks needed to write it back unchanged."""
    with open(path, encoding="utf-8") as handle:
        text = handle.read()
    style = {
        "spaced": '"sourceLanguage" : ' in text,
        "expand_empty": "{\n\n" in text,
        "trailing_newline": text.endswith("\n"),
    }
    return json.loads(text), style


def write(catalog, style, path):
    """Write the catalog back in the file's own style, so the diff is only the changed strings.

    These catalogs are not all written by the same tool: some use `"key" : value`, others
    `"key": value`, and they disagree about empty objects and the final newline. Key order is never
    re-sorted - Xcode's collation is not Python's, and sorting would reshuffle thousands of lines.
    """
    separators = (",", " : ") if style["spaced"] else (",", ": ")
    text = json.dumps(catalog, indent=2, ensure_ascii=False, separators=separators)

    if style["expand_empty"]:
        empty_line = re.compile(r"^(\s*).*?\{\}", re.MULTILINE)
        while "{}" in text:
            text = empty_line.sub(lambda m: m.group(0)[:-2] + "{\n\n" + m.group(1) + "}", text, count=1)

    if style["trailing_newline"]:
        text += "\n"

    with open(path, "w", encoding="utf-8") as handle:
        handle.write(text)


def main():
    arguments = sys.argv[1:]
    check_only = "--check" in arguments
    paths = [a for a in arguments if a != "--check"] or sorted(glob.glob("*/Localizable.xcstrings"))

    if not paths:
        print("warning: no String Catalogs found")
        return 0

    copied = 0
    needs_tutoiement = []
    no_french = []

    for path in paths:
        catalog, style = read(path)
        changed = False

        for key, entry in catalog.get("strings", {}).items():
            if not key.strip() or not entry.get("shouldTranslate", True):
                continue
            if entry.get("extractionState") == "stale":
                continue

            localizations = entry.get("localizations", {})
            if "fr-CA" in localizations:
                continue

            french = value_of(localizations, "fr")
            if french is None:
                no_french.append((path, key))
                continue

            if is_vouvoiement(french):
                needs_tutoiement.append((path, key, french))
                continue

            if not check_only:
                localizations["fr-CA"] = {"stringUnit": {"state": "translated", "value": french}}
                entry["localizations"] = {k: localizations[k] for k in sorted(localizations)}
                changed = True
            copied += 1

        if changed:
            write(catalog, style, path)

    verb = "would copy" if check_only else "copied"
    print(f"{verb} {copied} string(s) from fr into fr-CA")

    if needs_tutoiement:
        print(f"\n{len(needs_tutoiement)} string(s) address the user as \"vous\" and need fr-CA by hand:")
        for path, key, french in needs_tutoiement:
            print(f"  {path.split('/')[0]}: {key!r}\n      fr: {french}")

    if no_french:
        print(f"\n{len(no_french)} string(s) have no French at all, so fr-CA cannot be filled:")
        for path, key in no_french[:10]:
            print(f"  {path.split('/')[0]}: {key!r}")
        if len(no_french) > 10:
            print(f"  ... and {len(no_french) - 10} more")

    if check_only and (copied or needs_tutoiement):
        print("\nfr-CA is out of date. Run Scripts/sync-fr-ca.py and translate what it reports.")
        return 1

    return 1 if needs_tutoiement else 0


if __name__ == "__main__":
    sys.exit(main())
