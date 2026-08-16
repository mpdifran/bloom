# Watch App Architecture Patterns

This document outlines patterns specific to the watchOS companion app.

## Data Sync Patterns

### Application Context Sync

For syncing configuration/state data from iOS to watchOS, use the WatchConnectivity application context pattern.

#### iOS Side (Sender)

1. **Create a data model** in `BloomFoundation/Watch/`:
```swift
public struct WatchMyData: Codable, Sendable {
  public let someValue: String
  // ...
}
```

2. **Sync on foreground** in `BloomApp.swift`:
```swift
.onForegroundTask {
  await MyDataProvider.shared.syncToWatch()
}
```

3. **Send via WatchChannel**:
```swift
func syncToWatch() async {
  let watchData = WatchMyData(...)
  guard let data = try? JSONEncoder().encode(watchData) else { return }

  try? await WatchChannel.shared.updateApplicationContext(
    key: WatchChannel.myDataKey,
    data: data
  )
}
```

4. **Add key constant** in `WatchChannel.swift`:
```swift
public static let myDataKey = "myData"
```

#### Watch Side (Receiver)

1. **Create a provider** that listens to application context updates:
```swift
@Observable @MainActor
public final class MyDataProvider {
  public static let shared = MyDataProvider()

  public private(set) var myValue: String?

  private init() {
    loadFromUserDefaults()
    loadFromApplicationContext()

    // Listen for updates
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleApplicationContextUpdate),
      name: WatchChannel.applicationContextDidUpdate,
      object: nil
    )
  }

  @objc private func handleApplicationContextUpdate() {
    loadFromApplicationContext()
  }

  public func loadFromApplicationContext() {
    guard let data = WatchChannel.shared.getApplicationContextData(for: WatchChannel.myDataKey),
          let watchData = try? JSONDecoder().decode(WatchMyData.self, from: data) else {
      return
    }

    myValue = watchData.someValue
  }
}
```

**Key points:**
- Listen to `WatchChannel.applicationContextDidUpdate` notification
- Load from application context on init AND when notification fires
- Cache in UserDefaults.group for offline access

### Complication/Widget Priority Sync (iOS → watchOS)

For data that powers watchOS widgets/complications, use the dedicated complication transfer API for immediate updates.

#### Why Use Complication Transfers?

- **Priority delivery**: Gets through even when watch is in low-power state
- **Can wake the watch**: Doesn't wait for next sync opportunity
- **Guaranteed delivery**: Queued until delivered (unlike application context which is last-write-wins)
- **Daily budget**: ~50 transfers/day (check via `remainingComplicationTransfers`)

#### iOS Side (Sender)

```swift
func syncToWatch() async {
  let watchData = WatchMyData(...)
  guard let data = try? JSONEncoder().encode(watchData) else { return }

  // Use complication transfer for immediate widget update
  let remainingTransfers = await WatchChannel.shared.transferComplicationUserInfo(
    key: WatchChannel.myDataKey,
    data: data
  )

  if remainingTransfers < 10 {
    print("Warning: Only \(remainingTransfers) complication transfers remaining today")
  }

  // Also update application context as a fallback for watch app
  try? await WatchChannel.shared.updateApplicationContext(
    key: WatchChannel.myDataKey,
    data: data
  )
}
```

#### Watch Side (Receiver)

The `WatchChannel` automatically:
1. Receives data via `session(_:didReceiveUserInfo:)`
2. Stores in `UserDefaults.group` for widget access
3. Posts `WatchChannel.complicationUserInfoDidReceive` notification
4. Calls `WidgetCenter.shared.reloadTimelines(ofKind:)` to refresh widgets

For watch app providers, also listen to the complication notification:

```swift
private init() {
  // ... existing setup ...

  // Listen for priority complication updates
  NotificationCenter.default.addObserver(
    self,
    selector: #selector(handleComplicationUserInfo(_:)),
    name: WatchChannel.complicationUserInfoDidReceive,
    object: nil
  )
}

@objc private func handleComplicationUserInfo(_ notification: Notification) {
  guard let userInfo = notification.userInfo,
        userInfo[WatchChannel.myDataKey] != nil else {
    return
  }
  loadFromUserDefaults()
}
```

**Key points:**
- Use for widget-critical data only (limited daily budget)
- Always also update application context as fallback
- Watch providers should listen to both notifications
- Widget timelines are automatically reloaded by WatchChannel

### Direct Messaging (Watch → iOS)

For sending data from watch to iOS with immediate response:

1. **Create message models** in `BloomFoundation/Watch/`:
```swift
public struct WatchMyMessage: Codable, Sendable {
  public static let messageType = "myMessage"
  public let type: String
  public let data: MyData
}

public struct WatchMyResponse: Codable, Sendable {
  public let success: Bool
}
```

2. **Send from watch**:
```swift
let message = WatchMyMessage(...)
guard let data = try? JSONEncoder.watch.encode(message) else { return }

do {
  let responseData = try await WatchChannel.shared.send(data: data)
  let response = try JSONDecoder.watch.decode(WatchMyResponse.self, from: responseData)
  // Handle response
} catch {
  // Phone not reachable - queue for later
}
```

3. **Handle on iOS** in `BloomApp.swift`:
```swift
.task {
  await WatchChannel.shared.setMessageHandler { data in
    // Parse message type and handle
    // Return response data
  }
}
```

### Offline Queue Pattern

For data that must eventually reach the phone even when unavailable:

```swift
@MainActor
final class PendingDataManager {
  static let shared = PendingDataManager()

  private static let storageKey = "PendingDataManager.pending"
  @Published private(set) var pending: [MyData] = []

  func add(_ entry: MyData) async -> Bool {
    pending.append(entry)
    saveToStorage()

    let success = await sendEntry(entry)
    if success { remove(id: entry.id) }
    return success
  }

  func syncPending() async {
    for entry in pending {
      if await sendEntry(entry) {
        remove(id: entry.id)
      }
    }
  }

  private func saveToStorage() {
    guard let data = try? JSONEncoder.watch.encode(pending) else { return }
    UserDefaults.group.set(data, forKey: Self.storageKey)
  }
}
```

Call `syncPending()` on app launch in `BloomWatchApp.swift`.

### Sync rules, not rendered state

Anything whose correct value depends on the current time must sync as **rules the watch evaluates
itself**, never as a snapshot the phone resolved. A snapshot is stale the moment the clock moves, and
the watch has no way to tell how stale it is.

Reminders work this way. The phone sends `[ReminderPlan]` - the repeat rules plus today's completion
records - and the watch resolves them through `ReminderSchedule` in BloomFoundation, the same engine
`TodayView` uses on iOS. An occurrence therefore moves from upcoming to due to overdue, and the list
rolls over at midnight, with no sync at all.

- Shared engine: `BloomFoundation/Reminders/ReminderSchedule.swift` (pure, `Foundation`-only, unit
  tested in `BloomTests/Reminders/`)
- Shared storage: `BloomFoundation/Reminders/ReminderStore.swift` - the watch app and the widget
  extension read the same rules and pending completions from `UserDefaults.group`
- iOS mapping: `ReminderDTO.asPlan()` in DataContainer (SwiftData types can't cross to watchOS)

State that the user changes on the watch travels the other way as a **message**, not as synced state:
`PendingReminderCompletionManager` sends the completion and records a local
`ReminderCompletionOverride`. The override wins during resolution until the phone sends data that
agrees with it, so a completion never flickers back while the round trip is in flight.

When adding a field to a synced payload, make it optional so an older app on either side still
decodes; keep the resolved list alongside the rules until old builds age out.

### Push from the phone must work when the phone is in the background

The watch's `WatchSyncRequester` wakes the iOS app via WatchConnectivity to ask for a sync. That app
has no UI running, so any syncer that reads its data from a view model, or that early-returns when an
in-memory cache is empty, silently does nothing. Biological age was broken this way for months:
`syncBiologicalAgeToWatch()` returned immediately unless the You tab had already been visited in that
app session.

Syncers must load their own data (`BiologicalAgeCalculator.syncBiologicalAgeToWatch()` now calls
`loadLatestResult()` first) and must be `async` all the way to the `WCSession` call, so a
background-launched app isn't suspended mid-transfer.

### Never replace the application context

`WCSession.updateApplicationContext` **replaces** the whole dictionary. Every key shares one context,
so writing `[key: data]` directly wipes every other syncer's data. Always go through
`WatchChannel.updateApplicationContext(key:data:)`, which merges.

## UserDefaults

Always use `UserDefaults.group` (not `.standard`) for data that needs to persist:
```swift
UserDefaults.group.set(value, forKey: key)
```

## Sound & Haptics

Use `WKInterfaceDevice` for feedback:
```swift
WKInterfaceDevice.current().play(.success)  // Success haptic + sound
WKInterfaceDevice.current().play(.failure)  // Failure haptic + sound
```

## Examples in Codebase

- **Application Context Sync**: `BiologicalAgeProvider`, `WatchUnitPreferencesProvider`
- **Complication Priority Sync**: `WatchGoalSyncer`, `BiologicalAgeCalculator.syncToWatch()`
- **Direct Messaging**: `PendingBowelMovementManager`, `WatchBowelMovementHandler`
- **Offline Queue**: `PendingBowelMovementManager`
- **Rules, not rendered state**: `ReminderSchedule`, `ReminderStore`, `WatchTodaySyncer`, `TodayProvider`
