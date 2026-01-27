//
//  WatchUnitPreferencesProvider.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-01-26.
//

import Foundation
import HealthKit
import BloomFoundation

@Observable @MainActor
public final class WatchUnitPreferencesProvider {
  public static let shared = WatchUnitPreferencesProvider()

  public private(set) var weightUnit: HKUnit
  public private(set) var distanceUnit: HKUnit
  public private(set) var liquidVolumeUnit: HKUnit
  public private(set) var heightUnit: HKUnit

  private init() {
    // Default to locale-based units
    if Locale.current.measurementSystem == .metric {
      weightUnit = .gramUnit(with: .kilo)
      distanceUnit = .meterUnit(with: .kilo)
      heightUnit = .meterUnit(with: .centi)
    } else {
      weightUnit = .pound()
      distanceUnit = .mile()
      heightUnit = .foot()
    }

    switch Locale.current.measurementSystem {
    case .us:
      liquidVolumeUnit = .fluidOunceUS()
    case .uk:
      liquidVolumeUnit = .fluidOunceImperial()
    default:
      liquidVolumeUnit = .literUnit(with: .milli)
    }

    loadFromApplicationContext()
  }

  public func loadFromApplicationContext() {
    guard let data = WatchChannel.shared.getApplicationContextData(for: WatchChannel.unitPreferencesKey),
          let watchData = try? JSONDecoder().decode(WatchUnitPreferencesData.self, from: data) else {
      return
    }

    weightUnit = HKUnit(from: watchData.weightUnitString)
    distanceUnit = HKUnit(from: watchData.distanceUnitString)
    liquidVolumeUnit = HKUnit(from: watchData.liquidVolumeUnitString)
    heightUnit = HKUnit(from: watchData.heightUnitString)
  }
}
