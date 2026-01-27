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

  private static let weightUnitKey = "WatchUnitPreferencesProvider.weightUnit"
  private static let distanceUnitKey = "WatchUnitPreferencesProvider.distanceUnit"
  private static let liquidVolumeUnitKey = "WatchUnitPreferencesProvider.liquidVolumeUnit"
  private static let heightUnitKey = "WatchUnitPreferencesProvider.heightUnit"

  public private(set) var weightUnit: HKUnit {
    didSet { UserDefaults.group.set(weightUnit.unitString, forKey: Self.weightUnitKey) }
  }
  public private(set) var distanceUnit: HKUnit {
    didSet { UserDefaults.group.set(distanceUnit.unitString, forKey: Self.distanceUnitKey) }
  }
  public private(set) var liquidVolumeUnit: HKUnit {
    didSet { UserDefaults.group.set(liquidVolumeUnit.unitString, forKey: Self.liquidVolumeUnitKey) }
  }
  public private(set) var heightUnit: HKUnit {
    didSet { UserDefaults.group.set(heightUnit.unitString, forKey: Self.heightUnitKey) }
  }

  public var useMetricVolume: Bool {
    liquidVolumeUnit == .literUnit(with: .milli)
  }

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

    loadFromUserDefaults()
    loadFromApplicationContext()

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleApplicationContextUpdate),
      name: WatchChannel.applicationContextDidUpdate,
      object: nil
    )
  }

  private func loadFromUserDefaults() {
    if let unitString = UserDefaults.group.string(forKey: Self.weightUnitKey) {
      weightUnit = HKUnit(from: unitString)
    }
    if let unitString = UserDefaults.group.string(forKey: Self.distanceUnitKey) {
      distanceUnit = HKUnit(from: unitString)
    }
    if let unitString = UserDefaults.group.string(forKey: Self.liquidVolumeUnitKey) {
      liquidVolumeUnit = HKUnit(from: unitString)
    }
    if let unitString = UserDefaults.group.string(forKey: Self.heightUnitKey) {
      heightUnit = HKUnit(from: unitString)
    }
  }

  @objc private func handleApplicationContextUpdate() {
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
