//
//  HKUnit+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-26.
//

import Foundation
import HealthKit

public extension HKUnit {

  static func bpm() -> HKUnit {
    HKUnit.count().unitDivided(by: HKUnit.minute())
  }

  static func breathsPerMinute() -> HKUnit {
    HKUnit.count().unitDivided(by: HKUnit.minute())
  }

  static func vo2Max() -> HKUnit {
    HKUnit(from: "mL/min·kg")
  }

  static func mgPerDL() -> HKUnit {
    .gramUnit(with: .milli).unitDivided(by: .literUnit(with: .deci))
  }

  static func millisecond() -> HKUnit {
    .secondUnit(with: .milli)
  }
}

public extension HKUnit {

  var descriptiveUnitName: String {
    switch self {
    case .count():
      "Steps"
    case.fluidOunceUS():
      "oz (US)"
    case .fluidOunceImperial():
      "oz (UK)"
    default:
      unitString
    }
  }

  var sensibleUnitString: String {
    switch self {
    case .count():
      "steps"
    case.fluidOunceUS():
      "oz"
    case .fluidOunceImperial():
      "oz"
    case .bpm():
      "bpm"
    default:
      unitString
    }
  }

  @MainActor
  func localizedUnit() -> HKUnit {
    if HKUnit.distanceUnits.contains(self) {
      return HealthUnitPreferences.shared.distanceUnit
    } else if HKUnit.weightUnits.contains(self) {
      return HealthUnitPreferences.shared.weightUnit
    } else if HKUnit.liquidVolumeUnits.contains(self) {
      return HealthUnitPreferences.shared.liquidVolumeUnit
    } else if HKUnit.heightUnits.contains(self) {
      return HealthUnitPreferences.shared.heightUnit
    }
    return self
  }
}
