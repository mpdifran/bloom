//
//  ProposedGoal.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-19.
//

import DataContainer
import HealthKit
import SwiftData

struct ProposedGoal: Sendable, Identifiable, Hashable {
  let id = UUID()
  let habitID: PersistentIdentifier?
  let targetMetric: TargetMetric
  var value: Double
  var suggestedValue: Double
  let previousValue: Double?
  var unitString: String
  let startDate: Date = Date.now
  let vitalKind: VitalModel.Kind?
  let context: String?
  var hasUserEdited: Bool
}

extension ProposedGoal {

  var unit: HKUnit {
    HKUnit(from: unitString)
  }

  var quantity: HKQuantity {
    HKQuantity(unit: unit, doubleValue: value)
  }

  @MainActor
  var displayQuantity: String {
    quantity.displayString(for: unit, formatter: targetMetric.preferredFormatter)
  }

  @MainActor
  var displayQuantityNoUnits: String {
    quantity.displayString(for: unit, formatter: targetMetric.preferredFormatter, showUnits: false)
  }

  var previousQuantity: HKQuantity? {
    guard let previousValue else { return nil }

    return HKQuantity(unit: unit, doubleValue: previousValue)
  }

  @MainActor
  var displayPreviousQuantity: String? {
    previousQuantity?.displayString(for: unit, formatter: targetMetric.preferredFormatter)
  }

  var shouldShowPreviousQuantity: Bool {
    guard let previousValue else { return false }

    return abs(value - previousValue) > 1
  }

  var isNewHabit: Bool {
    previousValue == nil
  }

  var shouldShowSuggestedValue: Bool {
    hasUserEdited && abs(value - suggestedValue) > 1
  }

  @MainActor
  var displaySuggestedValue: String {
    let suggestedQuantity = HKQuantity(unit: unit, doubleValue: suggestedValue)

    return suggestedQuantity.displayString(for: unit, formatter: targetMetric.preferredFormatter)
  }
}
