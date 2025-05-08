//
//  WorkoutExercise+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-02.
//

import DataContainer

extension WorkoutExercise {

  @MainActor
  var measurementDescription: String {
    if let repsDescription {
      return repsDescription
    } else if let distanceQuantity, let distanceUnit {
      return distanceQuantity.displayString(for: distanceUnit.hkUnit)
    } else {
      return DateFormatter.timeIntervalHourMinuteSecondAbbreviated.string(from: DateComponents(second: Int(duration))) ?? ""
    }
  }
}
