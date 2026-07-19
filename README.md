# Bloom Health

Bloom is a health and wellness companion for iPhone and Apple Watch. It brings nutrition tracking, sleep, workouts, habits, biological age, and an AI health coach (Bud) together in one place, built on HealthKit.

[**Download on the App Store**](https://apps.apple.com/app/id6739955926)

## What's in this repo

| Directory | What it is |
|---|---|
| `Apps/Bloom` | iOS app, watchOS companion app, and app extensions (widgets, Screen Time / Family Controls) |
| `Apps/Gardener` | macOS admin tool for food data management |
| `Backend/Bloom-Backend` | Vapor (Swift) API server — Postgres, Redis, WebSockets, OpenAI integration |
| `Shared/BloomModel` | Models shared between clients and server |

Architecture docs: [ARCHITECTURE.md](ARCHITECTURE.md) · [WATCH_ARCHITECTURE.md](WATCH_ARCHITECTURE.md) · [CHAT_ARCHITECTURE.md](CHAT_ARCHITECTURE.md)

## Requirements

- Xcode 16+, Swift 6 (strict concurrency enabled)
- iOS 18.0+ / watchOS 11+
- Backend: Swift 6 toolchain, Docker (or local Postgres + Redis)

## Getting started

### iOS / watchOS / macOS apps

```bash
open Bloom.xcworkspace   # always the workspace, never the xcodeproj
```

Set your own development team and bundle identifiers in the xcconfig files under `Apps/Bloom/Configuration/`. Note some capabilities require Apple-granted entitlements on your own account:

- **Family Controls** (Screen Time features) — requires applying to Apple for the entitlement
- **HealthKit, WeatherKit, Sign in with Apple, App Groups** — configure for your team/bundle IDs

SwiftLint runs as part of the Xcode build.

### Backend

```bash
cd Backend/Bloom-Backend
cp .env.example .env     # fill in values — see comments in the file
docker-compose build
docker-compose up app
```

Or without Docker: `brew install redis && brew services start redis`, run Postgres locally, then `swift run`.

### Tests

- Apps: ⌘U in Xcode
- Backend: `swift test` in `Backend/Bloom-Backend`

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). PRs target the `develop` branch.

## License

Bloom is licensed under the [GNU AGPLv3](LICENSE). In short: you may use, modify, and redistribute this code, but derivative works — including ones offered as a network service — must be released under the same license.

The **Bloom name, icon, and brand assets are not licensed** — see [TRADEMARKS.md](TRADEMARKS.md). Analytics identifiers, public SDK keys, and similar client-shipped values in this repo are not credentials.
