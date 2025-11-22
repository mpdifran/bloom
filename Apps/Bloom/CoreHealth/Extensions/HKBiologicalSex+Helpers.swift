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

  var name: String {
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
}
