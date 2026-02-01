//
//  WatchSyncRequester.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-01-31.
//

import Foundation
import BloomFoundation

/// Requests fresh data syncs from the iOS app when the watch app opens.
@MainActor
final class WatchSyncRequester {
  static let shared = WatchSyncRequester()

  private static let lastRequestKey = "WatchSyncRequester.lastRequest"
  private static let cooldownInterval: TimeInterval = 5 * 60 // 5 minutes

  private(set) var lastSyncRequest: Date? {
    didSet {
      if let date = lastSyncRequest {
        UserDefaults.group.set(date.timeIntervalSince1970, forKey: Self.lastRequestKey)
      }
    }
  }

  private init() {
    loadLastRequest()
  }

  /// Requests a sync if enough time has passed since the last request (debounced).
  func requestSyncIfNeeded() async {
    guard shouldRequestSync() else { return }
    await requestSync()
  }

  /// Requests a full data sync from the iOS app.
  @discardableResult
  func requestSync() async -> Bool {
    let message = WatchSyncRequestMessage()

    guard let data = try? JSONEncoder.watch.encode(message) else {
      return false
    }

    do {
      let responseData = try await WatchChannel.shared.send(data: data)
      let response = try JSONDecoder.watch.decode(WatchSyncRequestResponse.self, from: responseData)

      if response.success {
        lastSyncRequest = Date()
      }

      return response.success
    } catch {
      // Phone not reachable
      return false
    }
  }

  private func shouldRequestSync() -> Bool {
    guard let lastRequest = lastSyncRequest else {
      return true
    }

    return Date().timeIntervalSince(lastRequest) >= Self.cooldownInterval
  }

  private func loadLastRequest() {
    let timestamp = UserDefaults.group.double(forKey: Self.lastRequestKey)
    if timestamp > 0 {
      lastSyncRequest = Date(timeIntervalSince1970: timestamp)
    }
  }
}
