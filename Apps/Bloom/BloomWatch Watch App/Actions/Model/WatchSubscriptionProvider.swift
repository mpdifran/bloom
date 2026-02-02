//
//  WatchSubscriptionProvider.swift
//  BloomWatch Watch App
//
//  Created by Claude on 2026-01-30.
//

import Foundation
import BloomFoundation

/// Provides subscription status on watchOS by reading from WatchConnectivity application context.
@Observable @MainActor
public final class WatchSubscriptionProvider {
  public static let shared = WatchSubscriptionProvider()

  private static let isSubscribedKey = "WatchSubscriptionProvider.isSubscribed"

  public private(set) var isSubscribed: Bool = false {
    didSet { saveToUserDefaults() }
  }

  private init() {
    loadFromUserDefaults()
    loadFromApplicationContext()

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

  /// Loads subscription data from WatchConnectivity application context
  public func loadFromApplicationContext() {
    guard let data = WatchChannel.shared.getApplicationContextData(for: WatchChannel.subscriptionDataKey),
          let subscriptionData = try? JSONDecoder.watch.decode(WatchSubscriptionData.self, from: data) else {
      return
    }

    isSubscribed = subscriptionData.isSubscribed
  }

  private func loadFromUserDefaults() {
    isSubscribed = UserDefaults.group.bool(forKey: Self.isSubscribedKey)
  }

  private func saveToUserDefaults() {
    UserDefaults.group.set(isSubscribed, forKey: Self.isSubscribedKey)
  }
}
