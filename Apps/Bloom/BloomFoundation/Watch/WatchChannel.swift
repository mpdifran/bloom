//
//  WatchChannel.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-09.
//

import WatchConnectivity
import HealthKit

public final actor WatchChannel: NSObject {
  public static let shared = WatchChannel()

  @AsyncStreamable private(set) public var receivedData: Data?

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
}

private extension WatchChannel {

  func didReceive(_ messageData: Data) async {
    self.receivedData = messageData
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
  }

  func sessionDidBecomeInactive(_ session: WCSession) {
    print("WCSession did become inactive")
  }

  func sessionDidDeactivate(_ session: WCSession) {
    print("WCSession did deactivate. Attempting reactivation.")
    WCSession.default.activate()
  }

  func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
    Task { [channel] in
      await channel.didReceive(messageData)
    }
  }
}
