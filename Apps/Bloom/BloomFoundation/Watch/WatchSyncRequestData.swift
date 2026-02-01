//
//  WatchSyncRequestData.swift
//  BloomFoundation
//
//  Created by Mark DiFranco on 2026-01-31.
//

import Foundation

/// Message sent from watch to phone to request a full data sync
public struct WatchSyncRequestMessage: Codable, Sendable {
  public static let messageType = "syncRequest"

  public let type: String

  public init() {
    self.type = Self.messageType
  }
}

/// Response from phone after processing a sync request
public struct WatchSyncRequestResponse: Codable, Sendable {
  public let success: Bool
  public let timestamp: Date

  public init(success: Bool, timestamp: Date = Date()) {
    self.success = success
    self.timestamp = timestamp
  }
}
