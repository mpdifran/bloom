//
//  HKCategoryValueMenstrualFlow+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-03.
//

import HealthKit

extension HKCategoryValueMenstrualFlow {

  var name: String {
    switch self {
    case .unspecified:
      "Unspecified"
    case .light:
      "Light"
    case .medium:
      "Medium"
    case .heavy:
      "Heavy"
    case .none:
      "None"
    @unknown default:
      "Unknown"
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
