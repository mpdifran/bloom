//
//  WatchUnitPreferencesData.swift
//  BloomFoundation
//
//  Created by Mark DiFranco on 2026-01-26.
//

import Foundation

public struct WatchUnitPreferencesData: Codable, Sendable {
  public let weightUnitString: String
  public let distanceUnitString: String
  public let liquidVolumeUnitString: String
  public let heightUnitString: String

  public init(
    weightUnitString: String,
    distanceUnitString: String,
    liquidVolumeUnitString: String,
    heightUnitString: String
  ) {
    self.weightUnitString = weightUnitString
    self.distanceUnitString = distanceUnitString
    self.liquidVolumeUnitString = liquidVolumeUnitString
    self.heightUnitString = heightUnitString
  }
}
