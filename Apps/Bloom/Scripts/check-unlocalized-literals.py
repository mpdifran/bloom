#!/usr/bin/env python3
"""Fail the build when a string literal is displayed without ever reaching a String Catalog.

`Text("literal")` takes a LocalizedStringKey and is looked up at runtime. `Text(someString)` is not
looked up at all - it renders whatever bytes it was handed. So a literal that travels through a
`String` property to a `Text` is invisible to every other check we have: it never gets extracted, so
the catalog never knows it exists, and the coverage gate reports 100% while the screen is in English.

That is not hypothetical. The Actions grid shipped this way in every language:

    ActionItem(image: .logWaterIcon, title: "Drinks", ...)   // title: String
    Text(title)                                              // no lookup, renders "Drinks"

"Drinks" was in the catalog, translated to "Boissons", and never once looked up.

This covers the other checks' blind spot: it finds `String` properties whose value reaches a `Text`
and flags literals passed into them. A property counts when its own type renders it, or when another
type in the same file renders a String property of that name - which is how the Actions grid worked,
the model and the view that draws it sitting side by side.

Fixing a report means one of:

  - `String(localized: "...", comment: "...")` at the call site, if the text should be translated
  - `Text(verbatim:)` in the view, if the property carries data rather than prose
  - typing the property `LocalizedStringKey`, if it only ever receives literals

Run from Apps/Bloom. Prints Xcode-style diagnostics and exits non-zero on any finding.
"""
import os
import re
import sys
from collections import defaultdict

SEARCH_ROOTS = ["Bloom", "BloomUI", "BloomWatch Watch App", "BloomWidgets",
                "BloomWatchWidgetsExtension", "CoreHealth", "DataContainer",
                "BloomFoundation", "SharedAppIntents"]

TYPE_DECL = re.compile(r"\b(?:struct|class|enum|actor)\s+(\w+)")

# `let title: String` / `var subtitle: String?` - a stored property, not a computed one.
STRING_PROP = re.compile(r"^[ \t]*(?:public |private |internal |fileprivate )?(?:let|var)\s+(\w+)\s*:\s*String\??\s*$",
                         re.MULTILINE)

# Positions that display a string. `Text(verbatim:)` is deliberately absent: it is the escape hatch.
DISPLAY_SINKS = [
    r"\bText\(\s*{name}\s*\)",
    r"\.navigationTitle\(\s*{name}\s*\)",
    r"\.navigationBarTitle\(\s*{name}\s*\)",
]

# A literal argument: `title: "Drinks"`. Interpolations are excluded - they cannot be catalog keys.
def literal_arg(param):
    return re.compile(r"\b" + re.escape(param) + r"\s*:\s*\"([^\"\\\n]{1,80})\"")


def swift_files():
    for root_name in SEARCH_ROOTS:
        if not os.path.isdir(root_name):
            continue
        for root, dirs, files in os.walk(root_name):
            dirs[:] = [d for d in dirs if d not in {"build", ".build", "DerivedData"}]
            for name in files:
                if name.endswith(".swift"):
                    yield os.path.join(root, name)


def preview_spans(source):
    """Byte ranges of #Preview blocks. Preview fixtures are not shipped, so literals there are fine."""
    spans = []
    for match in re.finditer(r"#Preview\b", source):
        brace = source.find("{", match.start())
        if brace < 0:
            continue
        depth, index = 0, brace
        while index < len(source):
            if source[index] == "{":
                depth += 1
            elif source[index] == "}":
                depth -= 1
                if depth == 0:
                    break
            index += 1
        spans.append((match.start(), index))
    return spans


def type_bodies(source):
    """(type name, body text) for each declaration, so properties are attributed to their own type.

    Scoping matters: several files declare a `title: String` in one struct and a
    `title: LocalizedStringKey` in another, and treating the file as one namespace produces
    confident nonsense about both.
    """
    bodies = []
    for match in TYPE_DECL.finditer(source):
        brace = source.find("{", match.end())
        if brace < 0:
            continue
        depth, index = 0, brace
        while index < len(source):
            if source[index] == "{":
                depth += 1
            elif source[index] == "}":
                depth -= 1
                if depth == 0:
                    break
            index += 1
        bodies.append((match.group(1), source[brace:index]))
    return bodies


def collect(paths):
    """Returns {(Type, prop)} for String properties whose value reaches a Text.

    Two ways a property qualifies:

      1. Its own type renders it - `let title: String` and `Text(title)` in the same type.
      2. Another type *in the same file* renders a property of that name. This is how the Actions
         grid worked: ActionItem holds the title, the ActionGridCell beside it renders it, and the
         literal is written at the ActionItem call. Resolving `ActionGridCell(title: item.title)`
         back to ActionItem properly needs type inference; the file is a good enough proxy, because
         a view and the little model it renders are written together.

    Scoped to the file on purpose. Matching the name across the whole codebase instead pulls in every
    unrelated `title: String` on a model type - 155 reports, nearly all of them types whose value
    never reaches a Text at all.
    """
    sinks = set()
    for path in paths:
        try:
            source = open(path, encoding="utf-8").read()
        except OSError:
            continue
        bodies = type_bodies(source)
        props_by_type = {}
        for type_name, body in bodies:
            props_by_type[type_name] = {m.group(1) for m in STRING_PROP.finditer(body)}

        # Only a *String* property being rendered counts. A type may legitimately hold canonical
        # English in a String and wrap it at the display site - LocalizedStringKey(suggestion.title)
        # in the onboarding focus cards - and counting that render would flag the canonical value.
        displayed_in_file = set()
        for type_name, body in bodies:
            for pattern in DISPLAY_SINKS:
                for m in re.finditer(pattern.format(name=r"(\w+)"), body):
                    if m.group(1) in props_by_type.get(type_name, ()):
                        displayed_in_file.add(m.group(1))

        for type_name, props in props_by_type.items():
            for prop in props:
                if prop in displayed_in_file:
                    sinks.add((type_name, prop))
    return sinks


def main():
    paths = sorted(swift_files())
    if not paths:
        print("warning: no Swift sources found")
        return 0

    sinks = collect(paths)

    by_param = defaultdict(set)
    for type_name, prop in sinks:
        by_param[prop].add(type_name)

    findings = []
    for path in paths:
        source = open(path, encoding="utf-8").read()
        skip = preview_spans(source)
        for param, types in by_param.items():
            for match in literal_arg(param).finditer(source):
                if any(start <= match.start() <= end for start, end in skip):
                    continue
                # Only when the enclosing call is one of the types that displays this parameter.
                head = source[max(0, match.start() - 300):match.start()]
                calls = re.findall(r"\b([A-Z]\w+)\s*\(", head)
                if not calls or calls[-1] not in types:
                    continue
                line = source.count("\n", 0, match.start()) + 1
                findings.append((path, line, calls[-1], param, match.group(1)))

    for path, line, type_name, param, literal in sorted(findings):
        print(f'{path}:{line}: error: "{literal}" is passed to {type_name}.{param}, a String that is '
              f"displayed directly, so it never reaches a String Catalog and will render in English "
              f"in every language. Use String(localized:comment:), or Text(verbatim:) if it is data.")

    if findings:
        print(f"\n{len(findings)} unlocalized literal(s) reaching a Text.")
        return 1

    print(f"No unlocalized literals: checked {len(paths)} files, "
          f"{sum(len(v) for v in by_param.values())} displayed String properties")
    return 0


if __name__ == "__main__":
    sys.exit(main())
