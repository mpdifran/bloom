//
//  HealthUnitPreferences.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-15.
//

import Foundation
import HealthKit
import BloomFoundation

private extension String {
  enum Key {
    static let distanceUnit = "HealthUnitPreferences.distanceUnit"
    static let liquidVolumeUnit = "HealthUnitPreferences.liquidVolumeUnit"
    static let weightUnit = "HealthUnitPreferences.weightUnit"
    static let heightUnit = "HealthUnitPreferences.heightUnit"
  }
}

@MainActor @Observable
public final class HealthUnitPreferences {
  public static let shared = HealthUnitPreferences()

  public var distanceUnit: HKUnit {
    didSet {
      UserDefaults.group.set(distanceUnit.unitString, forKey: .Key.distanceUnit)
      Task { await syncToWatch() }
    }
  }
  public var liquidVolumeUnit: HKUnit {
    didSet {
      UserDefaults.group.set(liquidVolumeUnit.unitString, forKey: .Key.liquidVolumeUnit)
      Task { await syncToWatch() }
    }
  }
  public var weightUnit: HKUnit {
    didSet {
      UserDefaults.group.set(weightUnit.unitString, forKey: .Key.weightUnit)
      Task { await syncToWatch() }
    }
  }
  public var heightUnit: HKUnit {
    didSet {
      UserDefaults.group.set(heightUnit.unitString, forKey: .Key.heightUnit)
      Task { await syncToWatch() }
    }
  }

  private init() {
    if let unitString = UserDefaults.group.string(forKey: .Key.distanceUnit) {
      distanceUnit = HKUnit(from: unitString)
    } else {
      if Locale.current.measurementSystem == .metric {
        distanceUnit = .meterUnit(with: .kilo)
      } else {
        distanceUnit = .mile()
      }
    }
    if let unitString = UserDefaults.group.string(forKey: .Key.liquidVolumeUnit) {
      liquidVolumeUnit = HKUnit(from: unitString)
    } else {
      switch Locale.current.measurementSystem {
      case .us:
        liquidVolumeUnit = .fluidOunceUS()
      case .uk:
        liquidVolumeUnit = .fluidOunceImperial()
      default:
        liquidVolumeUnit = .literUnit(with: .milli)
      }
    }
    if let unitString = UserDefaults.group.string(forKey: .Key.weightUnit) {
      weightUnit = HKUnit(from: unitString)
    } else {
      if Locale.current.measurementSystem == .metric {
        weightUnit = .gramUnit(with: .kilo)
      } else {
        weightUnit = .pound()
      }
    }
    if let unitString = UserDefaults.group.string(forKey: .Key.heightUnit) {
      heightUnit = HKUnit(from: unitString)
    } else {
      if Locale.current.measurementSystem == .metric {
        heightUnit = .meterUnit(with: .centi)
      } else {
        heightUnit = .foot()
      }
    }
  }
}

public extension HealthUnitPreferences {

  func syncToWatch() async {
    #if os(iOS)
    let watchData = WatchUnitPreferencesData(
      weightUnitString: weightUnit.unitString,
      distanceUnitString: distanceUnit.unitString,
      liquidVolumeUnitString: liquidVolumeUnit.unitString,
      heightUnitString: heightUnit.unitString
    )

    guard let data = try? JSONEncoder.watch.encode(watchData) else { return }

    try? await WatchChannel.shared.updateApplicationContext(
      key: WatchChannel.unitPreferencesKey,
      data: data
    )
    #endif
  }
}

public extension HKUnit {

  static var distanceUnits: [HKUnit] {
    [
      .meterUnit(with: .kilo),
      .mile()
    ]
  }

  static var liquidVolumeUnits: [HKUnit] {
    [
      .literUnit(with: .milli),
      .fluidOunceUS(),
      .fluidOunceImperial()
    ]
  }

  static var weightUnits: [HKUnit] {
    [
      .gramUnit(with: .kilo),
      .pound()
    ]
  }

  static var heightUnits: [HKUnit] {
    [
      .meterUnit(with: .centi),
      .foot()
    ]
  }
}
