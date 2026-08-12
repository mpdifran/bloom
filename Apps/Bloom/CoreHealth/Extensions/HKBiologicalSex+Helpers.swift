//
//  HKBiologicalSex+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-25.
//

import HealthKit

extension HKBiologicalSex: CaseIterable {
  public static var allCases: [HKBiologicalSex] {
    [.notSet, .female, .male, .other]
  }
}

public extension HKBiologicalSex {

  /// Stable English name, used for logging, analytics and anything sent to the backend.
  /// Never localized — `name` is the display-facing counterpart.
  var canonicalName: String {
    switch self {
    case .notSet:
      "Prefer not to say"
    case .female:
      "Female"
    case .male:
      "Male"
    case .other:
      "Other"
    @unknown default:
      "Unknown"
    }
  }

  var name: String {
    switch self {
    case .notSet:
      String(localized: "Prefer not to say", bundle: Bundle.coreHealth)
    case .female:
      String(localized: "Female", bundle: Bundle.coreHealth)
    case .male:
      String(localized: "Male", bundle: Bundle.coreHealth)
    case .other:
      String(localized: "Other", bundle: Bundle.coreHealth)
    @unknown default:
      String(localized: "Unknown", bundle: Bundle.coreHealth)
    }
  }
}
