//
//  ProposedHabit.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-19.
//

import DataContainer
import HealthKit
import SwiftData

struct ProposedHabit: Sendable, Identifiable, Hashable {
    let id = UUID()
    let habitID: PersistentIdentifier?
    let targetMetric: TargetMetric
    var value: Double
    var suggestedValue: Double
    let previousValue: Double?
    let unitString: String
    let startDate: Date = Date.now
    let vitalKind: VitalModel.Kind?
    let context: String?
    var hasUserEdited: Bool
}

extension ProposedHabit {

    var unit: HKUnit {
        HKUnit(from: unitString)
    }

    var quantity: HKQuantity {
        HKQuantity(unit: unit, doubleValue: value)
    }

    var displayQuantity: String {
        quantity.displayString(for: unit, formatter: targetMetric.preferredFormatter)
    }

    var previousQuantity: HKQuantity? {
        guard let previousValue else { return nil }

        return HKQuantity(unit: unit, doubleValue: previousValue)
    }

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

    var displaySuggestedValue: String {
        let suggestedQuantity = HKQuantity(unit: unit, doubleValue: suggestedValue)

        return suggestedQuantity.displayString(for: unit, formatter: targetMetric.preferredFormatter)
    }
}
