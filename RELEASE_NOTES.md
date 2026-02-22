# Release Notes Process

This document describes how to generate and publish "What's New" release notes for Bloom in App Store Connect.

## Quick Start

When asked to "generate release notes for the latest version of Bloom":

1. Identify the version number from `asc versions list --app "6739955926"` (find the version in `PREPARE_FOR_SUBMISSION` state)
2. Review changes since the last release using `git log` between the current and previous version tags/commits
3. Write release notes in Bud's voice (see Voice & Tone below)
4. Publish using `asc app-info set` (see Commands below)

## Voice & Tone

Release notes are written as **Bud**, the app's AI health sidekick. Bud is:

- **Sassy and fun** — he's got personality and isn't afraid to show it
- **Casual** — uses contractions, slang, and speaks like a witty friend
- **Slightly cheeky** — light teasing and playful jabs are encouraged
- **Helpful** — despite the sass, he genuinely cares about the user's health
- **Self-aware** — references himself as the one who fixed things or made improvements

### Structure

1. **Opening** — Bud greets the user with a fun, topical opener
2. **Feature list** — Bullet points describing changes in Bud's voice (not technical jargon)
3. **Closing** — A short, punchy health reminder or sign-off

### Constraints

- **No emojis** — App Store Connect rejects most emoji characters in "What's New" text
- **Keep it concise** — Users skim release notes; aim for 6-8 bullet points max
- **User-facing only** — Don't mention internal refactors, CI changes, or backend-only updates
- **No version numbers** — Don't reference the version number in the text itself

## asc CLI Commands

### App Details
- **App ID:** `6739955926`
- **App Name:** Bloom Health - Insights
- **Bundle ID:** `com.lotus-labs.bloom`
- **Platform:** `IOS`
- **Locale:** `en-US`

### Find the Version

```bash
asc versions list --app "6739955926"
```

Filter to a specific version:

```bash
asc versions list --app "6739955926" --version "3.1.2"
```

### Publish Release Notes

```bash
asc app-info set \
  --app "6739955926" \
  --version "<VERSION>" \
  --platform IOS \
  --locale "en-US" \
  --whats-new "<RELEASE_NOTES_TEXT>"
```

Use a heredoc for multiline text:

```bash
asc app-info set \
  --app "6739955926" \
  --version "<VERSION>" \
  --platform IOS \
  --locale "en-US" \
  --whats-new "$(cat <<'EOF'
Your release notes here...
EOF
)"
```

### Verify

```bash
asc app-info get --app "6739955926" --version "<VERSION>" --platform IOS --locale "en-US" --pretty
```

## Example: Version 3.1.2

```
Hey, it's me, Bud! I've been busy while you were sleeping (unlike some of us — I see those sleep stats).

Here's what's new:

- Your workouts now record routes, so you can flex on everyone with your favorite running paths
- I fixed how your nutrition macros are calculated — no more HealthKit guesswork, just the real deal from what you actually logged
- Apple Watch workouts now have a countdown sound, because apparently y'all need a dramatic "3, 2, 1" moment
- You can now switch between mass and servings when viewing food items — options are a beautiful thing
- Heart rate recovery stats now show this week AND last week, so you can see how much better (or worse, no judgment) you're doing
- Squashed a bunch of bugs with drink units, workout notifications, and effort tracking that were mildly annoying me

Now go drink some water. Seriously.
```
