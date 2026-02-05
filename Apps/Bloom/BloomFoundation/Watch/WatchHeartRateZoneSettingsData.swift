//
//  WatchHeartRateZoneSettingsData.swift
//  BloomFoundation
//
//  Created by Claude on 2026-02-05.
//

import Foundation

/// Heart rate zone settings data synced from iOS to watch via application context
public struct WatchHeartRateZoneSettingsData: Codable, Sendable {
  public let mode: String // "automatic", "semiManual", "manual"
  public let maxHeartRate: Double
  public let restingHeartRate: Double
  public let zone1Threshold: Double
  public let zone2Threshold: Double
  public let zone3Threshold: Double
  public let zone4Threshold: Double
  public let zone5Threshold: Double
  public let lastUpdated: Date

  public init(
    mode: String,
    maxHeartRate: Double,
    restingHeartRate: Double,
    zone1Threshold: Double,
    zone2Threshold: Double,
    zone3Threshold: Double,
    zone4Threshold: Double,
    zone5Threshold: Double,
    lastUpdated: Date = Date()
  ) {
    self.mode = mode
    self.maxHeartRate = maxHeartRate
    self.restingHeartRate = restingHeartRate
    self.zone1Threshold = zone1Threshold
    self.zone2Threshold = zone2Threshold
    self.zone3Threshold = zone3Threshold
    self.zone4Threshold = zone4Threshold
    self.zone5Threshold = zone5Threshold
    self.lastUpdated = lastUpdated
  }
}

// MARK: - Watch → iOS Message

/// Message sent from watch to phone to update heart rate zone settings
public struct WatchHeartRateZoneSettingsMessage: Codable, Sendable {
  public static let messageType = "heartRateZoneSettings"

  public let type: String
  public let mode: String
  public let maxHeartRate: Double
  public let restingHeartRate: Double
  public let zone1Threshold: Double
  public let zone2Threshold: Double
  public let zone3Threshold: Double
  public let zone4Threshold: Double
  public let zone5Threshold: Double

  public init(
    mode: String,
    maxHeartRate: Double,
    restingHeartRate: Double,
    zone1Threshold: Double,
    zone2Threshold: Double,
    zone3Threshold: Double,
    zone4Threshold: Double,
    zone5Threshold: Double
  ) {
    self.type = Self.messageType
    self.mode = mode
    self.maxHeartRate = maxHeartRate
    self.restingHeartRate = restingHeartRate
    self.zone1Threshold = zone1Threshold
    self.zone2Threshold = zone2Threshold
    self.zone3Threshold = zone3Threshold
    self.zone4Threshold = zone4Threshold
    self.zone5Threshold = zone5Threshold
  }
}

/// Response from phone after processing heart rate zone settings update
public struct WatchHeartRateZoneSettingsResponse: Codable, Sendable {
  public let success: Bool
  public let timestamp: Date

  public init(success: Bool, timestamp: Date = Date()) {
    self.success = success
    self.timestamp = timestamp
  }
}
