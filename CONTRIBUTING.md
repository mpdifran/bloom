# Contributing to Bloom

Thanks for your interest in contributing!

## Before you start

Read [ARCHITECTURE.md](ARCHITECTURE.md) — it documents the patterns this codebase follows (ViewModels, model actors, networking, previews, scroll views, card containers). PRs that follow existing patterns get merged much faster. For watch code, also read [WATCH_ARCHITECTURE.md](WATCH_ARCHITECTURE.md).

## Development setup

Follow the Getting Started section in [README.md](README.md). Highlights:

- Always open `Bloom.xcworkspace`, not the xcodeproj
- Swift 6 strict concurrency is enabled — new code must be concurrency-clean
- SwiftLint runs during the Xcode build (don't run it from the CLI)
- Wrap every `#Preview` in `PreviewEnvironment {}`
- Use `BloomScrollView` for scroll views and `.cardContainer()` for list cells

## Branches and PRs

- Branch from and target **`develop`**. `develop` fast-forwards into `main` nightly; deploys run from `main`.
- Keep PRs focused — one feature or fix per PR.
- Include tests where the change is testable (backend especially: `swift test`).

## Sign-off (DCO)

We use the [Developer Certificate of Origin](https://developercertificate.org). Sign off each commit to certify you have the right to contribute the code:

```bash
git commit -s
```

## Health data

Never log or commit personal health data — in code, tests, fixtures, or issue reports. All HealthKit access goes through `HealthManager` in the `CoreHealth` framework.

## Reporting issues

Use GitHub Issues. For anything security-sensitive (credentials, data exposure, auth bypass), do **not** open a public issue — email the maintainer instead.
