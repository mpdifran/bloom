//
//  Habit+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-18.
//

import Foundation
import HealthKit
import BloomFoundation

private extension Double {
  static let defaultPrecision: Double = 0.05
}

public extension Habit {

  func duplicate() -> Habit {
    Habit(
      targetMetric: targetMetric,
      timePeriod: timePeriod,
      value: value,
      unitString: unitString,
      startDate: startDate,
      endDate: endDate,
      lastNotificationDate: lastNotificationDate,
      isSuggested: isSuggested,
      isUserEdited: isUserEdited,
      vitalKind: vitalKind,
      context: context
    )
  }
}

public extension Habit {

  var targetMetric: TargetMetric {
    get {
      TargetMetric(rawValue: rawTargetMetric) ?? .none
    }
    set {
      rawTargetMetric = newValue.rawValue
    }
  }

  var timePeriod: GoalTimePeriod {
    get {
      GoalTimePeriod(rawValue: rawTimePeriod) ?? .daily
    }
    set {
      rawTimePeriod = newValue.rawValue
    }
  }
}

public extension Habit {

  var unit: HKUnit {
    HKUnit(from: unitString)
  }

  var quantity: HKQuantity {
    HKQuantity(unit: unit, doubleValue: value)
  }

  /// If you update here, you need to update the method on `HabitDTO`.
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

public extension Array where Element == Habit {

  /// Finds the habit that was active on the given date, falling back to the oldest habit
  /// for dates before any habit existed. Assumes the array is sorted by startDate.
  func habit(for date: Date) -> Habit? {
    if let match = first(where: { $0.isDateWithinHabit(date: date) }) {
      return match
    }
    if let oldest = first, date < oldest.startDate {
      return oldest
    }
    return nil
  }
}

public extension Habit {

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
