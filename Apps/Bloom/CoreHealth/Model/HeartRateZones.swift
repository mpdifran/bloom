//
//  HeartRateZones.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-20.
//

import Foundation
import HealthKit
import BloomFoundation

public struct HeartRateZones: Hashable, Sendable {
  public let heartRateReserve: Double
  public let restingHeartRate: Double
  public let maxHeartRate: Double
  public let zone1: Double
  public let zone2: Double
  public let zone3: Double
  public let zone4: Double
  public let zone5: Double

  public init(
    heartRateReserve: Double,
    restingHeartRate: Double,
    maxHeartRate: Double,
    zone1: Double,
    zone2: Double,
    zone3: Double,
    zone4: Double,
    zone5: Double
  ) {
    self.heartRateReserve = heartRateReserve
    self.restingHeartRate = restingHeartRate
    self.maxHeartRate = maxHeartRate
    self.zone1 = zone1
    self.zone2 = zone2
    self.zone3 = zone3
    self.zone4 = zone4
    self.zone5 = zone5
  }
}

public extension HeartRateZones {

    var zone1RangeString: String {
        "\(zone1.format()) - \(zone2.format()) bpm"
    }

    var zone2RangeString: String {
        "\(zone2.format()) - \(zone3.format()) bpm"
    }

    var zone3RangeString: String {
        "\(zone3.format()) - \(zone4.format()) bpm"
    }

    var zone4RangeString: String {
        "\(zone4.format()) - \(zone5.format()) bpm"
    }

    var zone5RangeString: String {
        "\(zone5.format()) - \(maxHeartRate.format()) bpm"
    }
}
