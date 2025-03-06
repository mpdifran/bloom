//
//  HabitDTO+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-26.
//

import Foundation
import DataContainer
import HealthKit

private extension Double {
  static let defaultPrecision: Double = 0.05
}

extension HabitDTO {

  @MainActor
  var displayQuantity: String {
    quantity.displayString(for: unit)
  }

  var rangeMinGoal: HKQuantity {
    let goalValue = quantity.doubleValue(for: unit)
    let minGoal = goalValue * (1.0 - .defaultPrecision)
    return HKQuantity(unit: unit, doubleValue: minGoal)
  }

  var rangeMaxGoal: HKQuantity {
    let goalValue = quantity.doubleValue(for: unit)
    let minGoal = goalValue * (1.0 + .defaultPrecision)
    return HKQuantity(unit: unit, doubleValue: minGoal)
  }
}
