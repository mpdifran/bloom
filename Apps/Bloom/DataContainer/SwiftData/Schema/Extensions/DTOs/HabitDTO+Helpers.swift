//
//  HabitDTO+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-02.
//

import Foundation
import HealthKit

private extension Double {
  static let defaultPrecision: Double = 0.05
}

public extension HabitDTO {

  var unit: HKUnit {
    HKUnit(from: unitString)
  }

  var quantity: HKQuantity {
    HKQuantity(unit: unit, doubleValue: value)
  }

  /// If you update here, you need to update the method on `Habit`.
  func quantityMeetsGoal(_ otherQuantity: HKQuantity, gracePercent: Double = 0) -> Bool {
    guard quantity.is(compatibleWith: unit) else { return false }

    let clampedGracePercent = min(max(0, gracePercent), 1)

    switch targetMetric.measurementStyle {
    case .minimum:
      return otherQuantity.doubleValue(for: unit) >= value * (1 - clampedGracePercent)
    case .range:
      let value = otherQuantity.doubleValue(for: unit)
      let goal = quantity.doubleValue(for: unit)

      let resultPrecision = .defaultPrecision + clampedGracePercent

      return value.isWithinRange(of: goal, precision: resultPrecision)
    }
  }
}

public extension Array where Element == HabitDTO {

  /// Finds the habit that was active on the given date, falling back to the oldest habit
  /// for dates before any habit existed. Assumes the array is sorted by startDate.
  func habit(for date: Date) -> HabitDTO? {
    if let match = first(where: { $0.isDateWithinHabit(date: date) }) {
      return match
    }
    if let oldest = first, date < oldest.startDate {
      return oldest
    }
    return nil
  }
}

public extension HabitDTO {

  func isDateWithinHabit(date: Date) -> Bool {
    if Calendar.current.isDate(date, inSameDayAs: startDate) {
      return true
    }

    if let endDate {
      let startOfEndDate = Calendar.current.startOfDay(for: endDate)

      return date >= self.startDate && date < startOfEndDate
    }
    return date >= self.startDate
  }
}
