//
//  Habit+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-18.
//

import Foundation
import HealthKit

public extension Habit {

    var quantity: HKQuantity {
        HKQuantity(unit: self.unit, doubleValue: self.value)
    }

    var unit: HKUnit {
        HKUnit(from: self.unitString)
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
