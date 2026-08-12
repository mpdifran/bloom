//
//  HKCategoryValueVaginalBleeding+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-03.
//

import HealthKit

public extension HKCategoryValueVaginalBleeding {

  var name: String {
    switch self {
    case .unspecified:
      String(localized: "Unspecified", bundle: Bundle.coreHealth)
    case .light:
      String(localized: "Light", bundle: Bundle.coreHealth)
    case .medium:
      String(localized: "Medium", bundle: Bundle.coreHealth)
    case .heavy:
      String(localized: "Heavy", bundle: Bundle.coreHealth)
    case .none:
      String(localized: "None", bundle: Bundle.coreHealth)
    @unknown default:
      String(localized: "Unknown", bundle: Bundle.coreHealth)
    }
  }

  var indicatesBeginningOfCycle: Bool {
    switch self {
    case .medium, .heavy:
      return true
    default:
      return false
    }
  }
}
