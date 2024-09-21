//
//  Habit+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-18.
//

import Foundation
import HealthKit

public extension Habit {

    var unit: HKUnit {
        HKUnit(from: unitString)
    }

    var quantity: HKQuantity {
        HKQuantity(unit: unit, doubleValue: value)
    }

    func quantityExceedsGoal(_ quantity: HKQuantity) -> Bool {
        guard quantity.is(compatibleWith: unit) else { return false }

        return quantity.compare(self.quantity) == .orderedDescending
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
