//
//  WatchBiologicalAgeData.swift
//  BloomFoundation
//
//  Created by Claude on 2026-01-26.
//

import Foundation

/// Lightweight biological age data for watch synchronization.
/// Contains only the data needed by the watchOS UI.
public struct WatchBiologicalAgeData: Codable, Sendable {
  public let biologicalAge: Double
  public let actualAge: Double
  public let lastCalculated: Date

  public init(biologicalAge: Double, actualAge: Double, lastCalculated: Date) {
    self.biologicalAge = biologicalAge
    self.actualAge = actualAge
    self.lastCalculated = lastCalculated
  }
}
