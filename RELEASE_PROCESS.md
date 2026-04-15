# Release Process

This document describes the post-release process after a new version of Bloom is available on the App Store.

## Prerequisites

- The new version is live on the App Store
- Release notes have been published (see `RELEASE_NOTES.md`)

## Procedure

### 1. Create a GitHub Release

Create a release on GitHub tied to the commit that was used for the App Store release.

- **Tag**: Use the version number (e.g., `3.1.4`)
- **Target**: The commit that was built and submitted to the App Store
- **Title**: The version number (e.g., `3.1.4`)
- **Notes**: Include the same release notes that were published to the App Store

```bash
gh release create "X.X.X" --target <commit-sha> --title "X.X.X" --notes "<release-notes>"
```

### 2. Bump the Version

Increment the version by a **patch** (e.g., `3.1.4` → `3.1.5`). Always bump by patch — change it later if the scope of upcoming work warrants a minor or major version change.

The version is controlled by `MARKETING_VERSION` in the Xcode project build settings (`Apps/Bloom/Bloom.xcodeproj`). This is the single source of truth — all targets inherit this value. Change it in one place in the Bloom target's build settings and all targets will pick it up.

### 3. Commit and Push

Commit the version bump and push it to the remote:

```bash
git add -A
git commit -m "Updated version to X.X.X"
git push
```

This ensures TestFlight builds don't fail due to the version matching an already-released version on the App Store.
