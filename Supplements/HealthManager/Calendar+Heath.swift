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

    func closestPastDateMatchingHourAndMinute(
        components: DateComponents,
        referenceDate: Date = .now
    ) -> Date? {
        var currentDateComponents = dateComponents([.year, .month, .day], from: referenceDate)

        currentDateComponents.hour = components.hour
        currentDateComponents.minute = components.minute
        currentDateComponents.second = 0

        if let potentialDate = date(from: currentDateComponents) {
            if potentialDate <= referenceDate {
                return potentialDate
            } else if let previousDay = date(byAdding: .day, value: -1, to: potentialDate) {
                return previousDay
            }
        }
        return nil
    }

    func isDate(_ date1: Date, nextDayAfter date2: Date) -> Bool {
        guard let nextDay = self.date(byAdding: .day, value: 1, to: date2) else { return false }

        return self.isDate(date1, inSameDayAs: nextDay)
    }

    func startOfWeek(for date: Date) -> Date? {
        let components = self.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components)
    }

    func startOfNextWeek(for date: Date) -> Date? {
        guard let nextWeek = self.date(byAdding: .day, value: 7, to: date) else { return nil }

        return self.startOfWeek(for: nextWeek)
    }
}
