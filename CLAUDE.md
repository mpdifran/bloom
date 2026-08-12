# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Before Starting Any Work

**IMPORTANT**: Always read and review `ARCHITECTURE.md` before beginning any development work. This file contains:
- Established patterns and conventions
- Preferred coding styles and approaches
- Common utilities and extensions
- Testing patterns
- Code organization principles

For watchOS development, also review `WATCH_ARCHITECTURE.md` which documents:
- Application context sync patterns (iOS → Watch)
- Direct messaging patterns (Watch → iOS)
- Offline queue patterns for unreliable connectivity
- UserDefaults.group usage

Following these patterns ensures consistency across the codebase and prevents architectural drift.

## Project Overview

Bloom is a comprehensive health and wellness ecosystem consisting of:
- **iOS App**: Main health tracking app with nutrition, sleep, workouts, habits, and AI chat (iOS 18.0+ minimum)
- **watchOS App**: Companion app for workout tracking and health metrics
- **macOS App (Gardener)**: Admin tool for food item management and data verification
- **Backend**: Vapor-based API with PostgreSQL, Redis, WebSocket support, and OpenAI integration

## Essential Commands

### iOS/watchOS Development
```bash
# Open the workspace (always use workspace, not xcodeproj)
open Bloom.xcworkspace

# Run SwiftLint
./Apps/Bloom/Scripts/swiftlint.sh

# Fastlane commands (from project root)
bundle exec fastlane ios setupMatch    # Setup certificates
bundle exec fastlane ios registerDevices # Register new devices
```

### Backend Development
```bash
# Navigate to backend
cd Backend/Bloom-Backend

# Local development with Docker
docker-compose build
docker-compose up app

# Local development without Docker
swift run   # Requires Redis: brew install redis && brew services start redis

# Database operations
./revert.sh  # Revert last migration
```

### Testing
- Run tests through Xcode (⌘U) or Xcode Cloud
- Backend tests: `swift test` in Backend/Bloom-Backend directory
- **Note**: Do not attempt to build the iOS app via command line to test changes - the build process is complex and time-consuming
- **Note**: SwiftLint will crash when run via command line - don't run it during development. The Xcode build process handles linting automatically

## Architecture Highlights

### Data Flow
1. **SwiftData Models**: Located in `DataContainer/Schema/` - local persistence layer
2. **Shared Models**: `Shared/BloomModel/` - models shared between client and server
3. **HealthKit Integration**: `CoreHealth/` framework handles all health data operations
4. **Backend Communication**: Uses URLSession with custom endpoints in `Network/URLRequests/`

### Key Architectural Decisions
- **Modular Frameworks**: BloomFoundation (utilities), CoreHealth (HealthKit), DataContainer (SwiftData), ScreenControl (Family Controls)
- **App Extensions**: DeviceActivityMonitor, DeviceActivityReport, ShieldAction, ShieldConfiguration for Screen Time features
- **Strict Concurrency**: Swift 6 with complete concurrency checking enabled
- **WebSocket Support**: Real-time communication for chat and live updates

### Important Patterns
- **ViewModels**: Suffix with `ViewModel`, use `@Observable` macro
- **Actors**: Model actors in `DataContainer/ModelActors/` for thread-safe data access
- **Networking**: All API endpoints defined in `URLRequest+Endpoints.swift`
- **Error Handling**: Consistent error types per module

## Development Guidelines

### When Working with Health Data
- All HealthKit operations go through `HealthManager`
- Use `CoreHealth` framework types, not raw HKTypes
- Respect privacy - never log personal health data

### When Adding New Features
1. Check if similar functionality exists in the codebase first
2. Follow existing patterns for ViewModels, networking, and data persistence
3. Add appropriate telemetry events using TelemetryDeck
4. Consider watch app implications for health-related features

### Configuration
- Development/Production configs in `Configuration/` directory
- API endpoints and keys configured via .xcconfig files
- Backend config via environment variables (see docker-compose.yml)

### Common Pitfalls
- Always use the workspace file, not individual xcodeproj files
- SwiftData migrations must be carefully planned - no automatic rollback
- Watch connectivity requires proper session handling
- Family Controls APIs have strict entitlement requirements

### Localization
- User-facing text ships through String Catalogs (`Localizable.xcstrings`), one per target
- SwiftUI literals (`Text("…")`, `Button("…")`, `.navigationTitle("…")`) are extracted automatically - leave them alone
- Anything else - `String` display names, UIKit strings - uses `String(localized:comment:)`
- From a framework, pass its bundle: `String(localized: "…", bundle: Bundle.coreHealth)`
- Never let a localized string reach analytics, the backend, or persistence - use `canonicalName`/`rawValue` there
- See the "Localization" section in ARCHITECTURE.md before adding strings

### Preview Development
- ALWAYS wrap #Preview content in PreviewEnvironment {}. This exposes all the environment objects to the preview.
- This is required for any preview in the app - don't forget it!

### ScrollView Guidelines
- Use BloomScrollView for any scrollviews in the app. If the view is presented modally, and the chat bar is not visible, you can set showsChatBar to false. Otherwise the safe area will be inset at the bottom of the scroll view.

### List View Development
- Whenever you're building a cell in a list, use .cardContainer() to wrap it properly. You don't need to add padding, the view modifier will take care of that.

### Navigation
- Present and push via the type-erased `AnyView?` pattern: a `@State ... : AnyView?` binding + `.asAny`, using AppUI's `.sheet($)`, `.fullScreenCover($)`, and `.navigationDestination($)` overloads. Push with `binding = SomeView().asAny`, pop by setting it to `nil`. Don't hand-roll `NavigationLink`. For multi-level pushes, each pushed view owns its own binding + `.navigationDestination($)`. See the "Navigation & Presentation" section in ARCHITECTURE.md.

## Release Notes

When asked to generate or publish release notes, follow the process in `RELEASE_NOTES.md`. This covers:
- Writing "What's New" text in Bud's voice
- Publishing to App Store Connect via the `asc` CLI
- The app ID, platform, and locale to use

## Release Process

After a new version is live on the App Store, follow the process in `RELEASE_PROCESS.md`. This covers:
- Creating a GitHub release tied to the release commit
- Bumping the version (patch increment)
- Committing and pushing to prevent TestFlight version collisions

## Documentation Guidelines

When you discover new patterns, conventions, or important details about the codebase:
1. **Update CLAUDE.md** - Add project-specific instructions, commands, or guidelines
2. **Update ARCHITECTURE.md** - Document architectural patterns, conventions, and best practices
3. Always document learnings to help maintain consistency and knowledge across sessions
