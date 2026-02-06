//
//  WatchConfirmationData.swift
//  BloomFoundation
//
//  Created by Claude on 2026-02-05.
//

import Foundation

/// Data synced via application context to confirm which entries have been saved on iOS.
/// This provides a backup confirmation mechanism when direct message responses are lost.
public struct WatchConfirmationData: Codable, Sendable, Equatable {
  /// IDs of bowel movement entries that have been successfully saved on iOS
  public let confirmedBowelMovementIDs: [String]

  /// IDs of food log entries that have been successfully saved on iOS
  public let confirmedFoodLogIDs: [String]

  public init(
    confirmedBowelMovementIDs: [String] = [],
    confirmedFoodLogIDs: [String] = []
  ) {
    self.confirmedBowelMovementIDs = confirmedBowelMovementIDs
    self.confirmedFoodLogIDs = confirmedFoodLogIDs
  }
}
