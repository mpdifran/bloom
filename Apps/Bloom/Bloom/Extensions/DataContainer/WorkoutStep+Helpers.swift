//
//  WorkoutStep+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-30.
//

import DataContainer

extension WorkoutStep {

  @MainActor
  var parameterDescription: String {
    [
      durationDescription,
      distanceDescription,
      repsDescription
    ]
      .compactMap { $0 }
      .joined(separator: " • ")
  }

  @MainActor
  var distanceDescription: String? {
    guard let distanceQuantity, let distanceUnit else { return nil }

    return distanceQuantity.displayString(for: distanceUnit.hkUnit)
  }
}
