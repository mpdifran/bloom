//
//  WatchBowelMovementData.swift
//  BloomFoundation
//
//  Created by Mark DiFranco on 2026-01-27.
//

import Foundation

/// Entry representing a bowel movement logged on the watch
public struct WatchBowelMovementEntry: Codable, Sendable, Identifiable {
  public let id: String
  public let date: Date
  public let bristolStoolType: Int
  public let rawDuration: Int

  public init(
    id: String = UUID().uuidString,
    date: Date = .now,
    bristolStoolType: Int,
    rawDuration: Int
  ) {
    self.id = id
    self.date = date
    self.bristolStoolType = bristolStoolType
    self.rawDuration = rawDuration
  }
}

/// Message wrapper for bowel movement data sent from watch to phone
public struct WatchBowelMovementMessage: Codable, Sendable {
  public static let messageType = "bowelMovement"

  public let type: String
  public let entry: WatchBowelMovementEntry

  public init(entry: WatchBowelMovementEntry) {
    self.type = Self.messageType
    self.entry = entry
  }
}

/// Response from phone after processing a bowel movement entry
public struct WatchBowelMovementResponse: Codable, Sendable {
  public let success: Bool
  public let entryId: String

  public init(success: Bool, entryId: String) {
    self.success = success
    self.entryId = entryId
  }
}
