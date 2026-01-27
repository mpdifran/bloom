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
- **Direct Messaging**: `PendingBowelMovementManager`, `WatchBowelMovementHandler`
- **Offline Queue**: `PendingBowelMovementManager`
