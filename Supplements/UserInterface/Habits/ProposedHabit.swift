//
//  ProposedHabit.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-19.
//

import DataContainer
import HealthKit

struct ProposedHabit: Sendable, Identifiable {
    let id = UUID()
    let targetMetric: TargetMetric
    var value: Double
    var suggestedValue: Double
    let previousValue: Double?
    let unitString: String
    let startDate: Date = Date.now
    let vitalKind: VitalModel.Kind?
    let context: String?
    var hasUserEdited: Bool = false
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
}
