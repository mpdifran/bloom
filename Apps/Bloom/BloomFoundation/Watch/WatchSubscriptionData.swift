//
//  WatchSubscriptionData.swift
//  BloomFoundation
//
//  Created by Claude on 2026-01-30.
//

import Foundation

/// Data synced from iOS to watch containing subscription status.
public struct WatchSubscriptionData: Codable, Sendable {
  public let isSubscribed: Bool
  public let lastUpdated: Date

  public init(
    isSubscribed: Bool,
    lastUpdated: Date = Date()
  ) {
    self.isSubscribed = isSubscribed
    self.lastUpdated = lastUpdated
  }
}
