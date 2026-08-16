//
//  WatchChannel.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-09.
//

import WatchConnectivity
import HealthKit
#if os(watchOS)
import WidgetKit
#endif

public final actor WatchChannel: NSObject {
  public static let heartRateZoneSettingsKey = "heartRateZoneSettings"
  public static let biologicalAgeKey = "biologicalAge"
  public static let unitPreferencesKey = "unitPreferences"
  public static let todayDataKey = "todayData"
  public static let foodDataKey = "foodData"
  public static let subscriptionDataKey = "subscriptionData"
  public static let goalsDataKey = "goalsData"
  public static let confirmationDataKey = "confirmationData"
  public static let biologicalSexDataKey = "biologicalSexData"
  public static let shared = WatchChannel()

  /// Notification posted when complication user info is received (watchOS only)
  public static let complicationUserInfoDidReceive = Notification.Name("WatchChannel.complicationUserInfoDidReceive")

  public static let applicationContextDidUpdate = Notification.Name("WatchChannel.applicationContextDidUpdate")

  @AsyncStreamable private(set) public var receivedData: Data?

  /// Handler for processing incoming messages that require a reply (iOS only)
  /// Set this to handle messages from the watch and return response data
  public var messageHandler: (@Sendable (Data) async -> Data)?

  /// Pending context updates to send when session activates
  private var pendingContextUpdates: [String: Data] = [:]

  private override init() {
    super.init()

    if WCSession.isSupported() {
      let sessionDelegate = WatchSessionDelegate(channel: self)
      WCSession.default.delegate = sessionDelegate
      WCSession.default.activate()
      self.sessionDelegate = sessionDelegate
    }
  }

  private var sessionDelegate: WatchSessionDelegate!
}

public extension WatchChannel {

  func send(data: Data) async throws -> Data {
    try await withCheckedThrowingContinuation { continuation in
      WCSession.default.sendMessageData(data) { data in
        continuation.resume(returning: data)
      } errorHandler: { error in
        continuation.resume(throwing: error)
      }
    }
  }

  func updateApplicationContext(key: String, data: Data) throws {
    if WCSession.default.activationState == .activated {
      // Merge with existing context instead of replacing
      var context = WCSession.default.applicationContext
      context[key] = data
      try WCSession.default.updateApplicationContext(context)
    } else {
      // Queue for when session activates
      pendingContextUpdates[key] = data
    }
  }

  /// Flushes any pending context updates that were queued before session activation
  func flushPendingContextUpdates() {
    guard WCSession.default.activationState == .activated,
          !pendingContextUpdates.isEmpty else { return }

    // Merge all pending updates into one context update
    var context = WCSession.default.applicationContext
    for (key, data) in pendingContextUpdates {
      context[key] = data
    }

    do {
      try WCSession.default.updateApplicationContext(context)
      pendingContextUpdates.removeAll()
    } catch {
      // Keep queued for next attempt
      print("Failed to flush pending context updates: \(error)")
    }
  }

  nonisolated func getApplicationContextData(for key: String) -> Data? {
    WCSession.default.receivedApplicationContext[key] as? Data
  }

  #if os(iOS)
  /// Transfers data to the watch using the priority complication channel.
  /// This API is specifically designed for keeping complications/widgets up to date.
  /// - Important: This has a daily budget (~50 transfers). Use for widget-critical data only.
  /// - Parameters:
  ///   - key: The key identifying the data type
  ///   - data: The encoded data to transfer
  /// - Returns: The number of remaining complication transfers for today
  @discardableResult
  func transferComplicationUserInfo(key: String, data: Data) -> Int {
    guard WCSession.default.activationState == .activated else {
      print("WCSession not activated, cannot transfer complication user info")
      return 0
    }

    #if targetEnvironment(simulator)
    // Simulator doesn't support complication transfers, fall back to application context
    try? updateApplicationContext(key: key, data: data)
    return 50
    #else
    guard WCSession.default.isComplicationEnabled else {
      // Fall back to application context if complications aren't enabled
      try? updateApplicationContext(key: key, data: data)
      return 0
    }

    WCSession.default.transferCurrentComplicationUserInfo([key: data])
    return WCSession.default.remainingComplicationUserInfoTransfers
    #endif
  }

  /// Returns the number of remaining complication user info transfers available today
  nonisolated var remainingComplicationTransfers: Int {
    #if targetEnvironment(simulator)
    return 50
    #else
    return WCSession.default.remainingComplicationUserInfoTransfers
    #endif
  }
  #endif

  /// Sets the handler for processing incoming messages that require a reply
  func setMessageHandler(_ handler: @escaping @Sendable (Data) async -> Data) {
    self.messageHandler = handler
  }
}

private extension WatchChannel {

  func didReceive(_ messageData: Data) async {
    self.receivedData = messageData
  }

  func handleMessage(_ messageData: Data) async -> Data {
    if let handler = messageHandler {
      return await handler(messageData)
    }
    // Return empty response if no handler is set
    return Data()
  }

  nonisolated func didReceiveApplicationContext() {
    DispatchQueue.main.async {
      NotificationCenter.default.post(name: Self.applicationContextDidUpdate, object: nil)
    }
  }

  func didReceiveUserInfo(_ userInfo: [String: Any]) {
    // Store received data in UserDefaults.group for widget access
    for (key, value) in userInfo {
      if let data = value as? Data {
        // Store with the same key the widgets expect
        switch key {
        case Self.goalsDataKey:
          // Decode and re-store for widget access
          if let goalData = try? JSONDecoder.watch.decode(WatchGoalData.self, from: data) {
            if let goalsData = try? JSONEncoder.watch.encode(goalData.goals) {
              UserDefaults.group.set(goalsData, forKey: "WatchGoalProvider.goals")
              UserDefaults.group.set(goalData.lastUpdated, forKey: "WatchGoalProvider.lastUpdated")
            }
          }
        case Self.biologicalAgeKey:
          // Decode and store individual values for widget access.
          // Every field is written: the provider reloads its whole state from these keys, so a
          // partial write would leave it showing a stale timestamp and stale contributing metrics.
          if let bioAgeData = try? JSONDecoder.watch.decode(WatchBiologicalAgeData.self, from: data) {
            UserDefaults.group.set(bioAgeData.biologicalAge, forKey: "BiologicalAgeProvider.biologicalAge")
            UserDefaults.group.set(bioAgeData.actualAge, forKey: "BiologicalAgeProvider.actualAge")
            UserDefaults.group.set(
              bioAgeData.lastCalculated.timeIntervalSince1970,
              forKey: "BiologicalAgeProvider.lastCalculated"
            )
            if let confidence = bioAgeData.confidence {
              UserDefaults.group.set(confidence.rawValue, forKey: "BiologicalAgeProvider.confidence")
            }
            if let contributions = bioAgeData.metricContributions,
               let contributionsData = try? JSONEncoder.watch.encode(contributions) {
              UserDefaults.group.set(contributionsData, forKey: "BiologicalAgeProvider.contributions")
            }
            if let chartData = bioAgeData.chartData,
               let chartDataData = try? JSONEncoder.watch.encode(chartData) {
              UserDefaults.group.set(chartDataData, forKey: "BiologicalAgeProvider.chartData")
            }
          }
        default:
          break
        }
      }
    }

    // Post notification for any observers. Observers are @MainActor, and this runs on the
    // WatchConnectivity queue, so hop to main the same way didReceiveApplicationContext does.
    let sendableUserInfo = userInfo.compactMapValues { $0 as? Data }
    DispatchQueue.main.async {
      NotificationCenter.default.post(
        name: Self.complicationUserInfoDidReceive,
        object: nil,
        userInfo: sendableUserInfo
      )
    }

    #if os(watchOS)
    // Immediately refresh widget timelines when complication data arrives
    for key in userInfo.keys {
      switch key {
      case Self.goalsDataKey:
        WidgetCenter.shared.reloadTimelines(ofKind: "WatchGoalWidget")
      case Self.biologicalAgeKey:
        WidgetCenter.shared.reloadTimelines(ofKind: "BiologicalAgeWidget")
      default:
        break
      }
    }
    #endif
  }
}

// MARK: - WatchSessionDelegate

private final class WatchSessionDelegate: NSObject, WCSessionDelegate {
  unowned let channel: WatchChannel

  init(channel: WatchChannel) {
    self.channel = channel
    super.init()
  }

  func session(
    _ session: WCSession,
    activationDidCompleteWith activationState: WCSessionActivationState,
    error: Error?
  ) {
    if let error {
      print(error)
    }

    // Flush any pending context updates
    if activationState == .activated {
      Task { [channel] in
        await channel.flushPendingContextUpdates()
      }
    }
  }

  #if os(iOS)
  func sessionDidBecomeInactive(_ session: WCSession) {
    print("WCSession did become inactive")
  }

  func sessionDidDeactivate(_ session: WCSession) {
    print("WCSession did deactivate. Attempting reactivation.")
    WCSession.default.activate()
  }
  #endif

  func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
    Task { [channel] in
      await channel.didReceive(messageData)
    }
  }

  func session(
    _ session: WCSession,
    didReceiveMessageData messageData: Data,
    replyHandler: @escaping (Data) -> Void
  ) {
    Task { [channel] in
      let response = await channel.handleMessage(messageData)
      replyHandler(response)
    }
  }

  func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
    channel.didReceiveApplicationContext()
  }

  func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
    Task { [channel] in
      await channel.didReceiveUserInfo(userInfo)
    }
  }
}
