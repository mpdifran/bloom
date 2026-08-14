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
      String(localized: "Unspecified", bundle: Bundle.coreHealth, comment: "Display name for category value vaginal bleeding")
    case .light:
      String(localized: "Light", bundle: Bundle.coreHealth, comment: "Display name for category value vaginal bleeding")
    case .medium:
      String(localized: "Medium", bundle: Bundle.coreHealth, comment: "Display name for category value vaginal bleeding")
    case .heavy:
      String(localized: "Heavy", bundle: Bundle.coreHealth, comment: "Display name for category value vaginal bleeding")
    case .none:
      String(localized: "None", bundle: Bundle.coreHealth, comment: "Display name for category value vaginal bleeding")
    @unknown default:
      String(localized: "Unknown", bundle: Bundle.coreHealth, comment: "Display name for category value vaginal bleeding")
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
