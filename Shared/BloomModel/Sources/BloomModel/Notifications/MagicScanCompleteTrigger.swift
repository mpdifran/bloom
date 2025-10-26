//
//  MagicScanCompleteTrigger.swift
//  BloomModel
//
//  Created by Claude on 2025-10-26.
//

import Foundation

/// Payload for Magic Scanner completion push notifications
public struct MagicScanCompleteTrigger: Codable, Sendable {
  /// The notification type identifier
  public static let notificationType = "magic_scan_complete"

  /// The type of notification (always "magic_scan_complete")
  public let type: String

  /// The processing identifier for the completed scan
  public let processingIdentifier: String

  public init(type: String, processingIdentifier: String) {
    self.type = type
    self.processingIdentifier = processingIdentifier
  }

  /// Creates a trigger with the correct notification type
  public init(processingIdentifier: String) {
    self.type = Self.notificationType
    self.processingIdentifier = processingIdentifier
  }
}
