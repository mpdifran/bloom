//
//  WatchChannel.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-09.
//

import WatchConnectivity
import HealthKit

public final actor WatchChannel: NSObject {
  public static let heartRateZonesKey = "heartRateZones"
  public static let biologicalAgeKey = "biologicalAge"
  public static let unitPreferencesKey = "unitPreferences"
  public static let todayDataKey = "todayData"
  public static let foodDataKey = "foodData"
  public static let subscriptionDataKey = "subscriptionData"
  public static let shared = WatchChannel()

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
      try WCSession.default.updateApplicationContext([key: data])
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
    var context: [String: Any] = [:]
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
    NotificationCenter.default.post(name: Self.applicationContextDidUpdate, object: nil)
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
}
