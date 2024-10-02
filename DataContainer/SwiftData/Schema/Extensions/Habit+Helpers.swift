//
//  Habit+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-18.
//

import Foundation
import HealthKit
import BloomFoundation

public extension Habit {

    var unit: HKUnit {
        HKUnit(from: unitString)
    }

    var quantity: HKQuantity {
        HKQuantity(unit: unit, doubleValue: value)
    }

    func quantityMeetsGoal(_ otherQuantity: HKQuantity) -> Bool {
        guard quantity.is(compatibleWith: unit) else { return false }

        switch targetMetric.measurementStyle {
        case .minimum:
            return otherQuantity.compare(self.quantity) == .orderedDescending
        case .range:
            let value = otherQuantity.doubleValue(for: unit)
            let goal = quantity.doubleValue(for: unit)

            return value.isWithinRange(of: goal, precision: 0.1)
        }
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
