//
//  Calendar+Heath.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-25.
//

import Foundation

extension Calendar {

    func sleepStartDate(previousDays: Int, endDate: Date) -> Date {
        if let startDate = date(byAdding: .day, value: -previousDays, to: endDate) {
            return date(bySettingHour: 15, minute: 0, second: 0, of: startDate) ?? startDate
        }
        return Date.now // We need a better fallback when this fails
    }

    func endOfDay(for date: Date) -> Date {
        let nextDay = self.date(byAdding: .day, value: 1, to: date)!
        return startOfDay(for: nextDay)
    }
}
