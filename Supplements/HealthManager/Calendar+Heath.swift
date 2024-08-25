//
//  Calendar+Heath.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-25.
//

import Foundation

extension Calendar {

    func isMorning(date: Date) -> Bool {
        guard let hour = dateComponents([.hour], from: date).hour else { return false }

        return hour > 6 && hour < 12
    }

    func sleepStartDate(previousDays: Int, endDate: Date) -> Date {
        if let startDate = date(byAdding: .day, value: -previousDays, to: endDate) {
            return date(bySettingHour: 15, minute: 0, second: 0, of: startDate) ?? startDate
        }
        return endDate
    }

    func sleepStartDate(previousMonths: Int, endDate: Date) -> Date {
        if let startDate = date(byAdding: .month, value: -previousMonths, to: endDate) {
            return date(bySettingHour: 15, minute: 0, second: 0, of: startDate) ?? startDate
        }
        return endDate
    }

    func normalizedSleepDate(for date: Date) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: date)
        components.hour = 9
        return Calendar.current.date(from: components) ?? date
    }

    func startOfTomorrow(for date: Date) -> Date {
        let nextDay = self.date(byAdding: .day, value: 1, to: date)!
        return startOfDay(for: nextDay)
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

    func isDateInYesterdayOrToday(_ date: Date) -> Bool {
        isDateInYesterday(date) || isDateInToday(date)
    }

    func startOfWeek(for date: Date) -> Date? {
        let components = self.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components)
    }

    func startOfNextWeek(for date: Date) -> Date? {
        guard let nextWeek = self.date(byAdding: .weekOfYear, value: 1, to: date) else { return nil }

        return self.startOfWeek(for: nextWeek)
    }
}
