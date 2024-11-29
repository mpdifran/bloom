//
//  DateRange.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-14.
//

import Foundation

public struct DateRange: Sendable, Hashable {
    public let start: Date
    public let end: Date

    public init(_ start: Date, _ end: Date) {
        self.start = start
        self.end = end
    }
}

public extension DateRange {

    var numberOfDaysInclusive: Int {
        (Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0) + 1
    }

    func contains(date: Date) -> Bool {
        start <= date && date <= end
    }

    func containsTodayDate() -> Bool {
        return Calendar.current.isDateInToday(end) || end > .now
    }
}

// MARK: Today

public extension DateRange {

    static func today() -> DateRange {
        let startDate = Calendar.current.startOfDay(for: .now)

        var components = DateComponents()
        components.day = 1
        components.second = -1
        guard let endOfDay = Calendar.current.date(byAdding: components, to: startDate) else {
            return DateRange(startDate, .now)
        }

        return DateRange(startDate, endOfDay)
    }

    static func yesterday() -> DateRange {
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now) else {
            return DateRange(.now, .now)
        }

        let startDate = Calendar.current.startOfDay(for: yesterday)
        let endDate = Calendar.current.endOfDay(for: yesterday)

        return DateRange(startDate, endDate)
    }

    static func tomorrow() -> DateRange {
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: .now) else {
            return DateRange(.now, .now)
        }

        let startDate = Calendar.current.startOfDay(for: tomorrow)
        let endDate = Calendar.current.endOfDay(for: tomorrow)

        return DateRange(startDate, endDate)
    }
}

// MARK: Start Of Week / Day

public extension DateRange {
    static func startOfDayToNow() -> DateRange {
        let endDate = Date.now
        let startDate = Calendar.current.startOfDay(for: endDate)

        return DateRange(startDate, endDate)
    }

    static func startOfWeekToNow() -> DateRange {
        let endDate = Date.now
        guard let startDate = Calendar.current.startOfWeek(for: endDate) else {
            return DateRange(endDate, endDate)
        }

        return DateRange(startDate, endDate)
    }

    static func startOfWeekToStartOfToday() -> DateRange {
        let endDate = Calendar.current.startOfDay(for: .now)
        guard let startDate = Calendar.current.startOfWeek(for: endDate) else {
            return DateRange(endDate, endDate)
        }
        return DateRange(startDate, endDate)
    }

    static func mondayMorningToNow() -> DateRange {
        let endDate = Date.now
        guard let startDate = Calendar.current.mondayMorning(for: endDate) else {
            return DateRange(endDate, endDate)
        }
        return DateRange(startDate, endDate)
    }

    static func mondayMorningToStartOfToday() -> DateRange {
        let endDate = Calendar.current.startOfDay(for: .now)
        guard let startDate = Calendar.current.mondayMorning(for: endDate) else {
            return DateRange(endDate, endDate)
        }
        return DateRange(startDate, endDate)
    }

    static func startOfWeekdayToStartOfToday(weekday: Calendar.Weekday) -> DateRange {
        let now = Date.now
        let endDate = Calendar.current.startOfDay(for: now)

        let currentWeekday = Calendar.current.component(.weekday, from: now)
        let daysDifference = (currentWeekday - weekday.rawValue + 7) % 7

        guard let startDate = Calendar.current.date(byAdding: .day, value: -daysDifference, to: endDate) else {
            return DateRange(endDate, endDate)
        }

        return DateRange(startDate, endDate)
    }

  static func duringDay(_ date: Date) -> DateRange {
    let startOfDay = Calendar.current.startOfDay(for: date)
    guard let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) else {
      return DateRange(startOfDay, startOfDay)
    }

    return DateRange(startOfDay, endOfDay)
  }
}

// MARK: Trailing Ranges

public extension DateRange {
    static func trailingHoursFromNow(_ numberOfHours: Int) -> DateRange {
        let endDate = Date.now

        guard let startDate = Calendar.current.date(byAdding: .hour, value: -numberOfHours, to: endDate) else {
            return DateRange(endDate, endDate)
        }
        return DateRange(startDate, endDate)
    }

    static func trailingDaysFromNow(_ numberOfDays: Int) -> DateRange {
        let endDate = Date.now

        guard let startDate = Calendar.current.date(byAdding: .day, value: -numberOfDays, to: endDate) else {
            return DateRange(endDate, endDate)
        }
        return DateRange(startDate, endDate)
    }

    static func trailingDaysFromStartOfToday(_ numberOfDays: Int) -> DateRange {
        let endDate = Calendar.current.startOfDay(for: .now)

        guard let startDate = Calendar.current.date(byAdding: .day, value: -numberOfDays, to: endDate) else {
            return DateRange(endDate, endDate)
        }
        return DateRange(startDate, endDate)
    }

    static func trailingDaysFromStartOfWeek(_ numberOfDays: Int) -> DateRange {
        guard
            let endDate = Calendar.current.startOfWeek(for: .now),
            let startDate = Calendar.current.date(byAdding: .day, value: -numberOfDays, to: endDate)
        else {
            return DateRange(.now, .now)
        }
        return DateRange(startDate, endDate)
    }

    static func trailingDays(from date: Date, numberOfDays: Int) -> DateRange {
        guard
            let startDate = Calendar.current.date(byAdding: .day, value: -numberOfDays, to: date)
        else {
            return DateRange(date, date)
        }
        return DateRange(startDate, date)
    }

    static func trailingWeeksFromNow(_ numberOfWeeks: Int) -> DateRange {
        let endDate = Date.now

        guard let startDate = Calendar.current.date(byAdding: .weekOfYear, value: -numberOfWeeks, to: endDate) else {
            return DateRange(endDate, endDate)
        }
        return DateRange(startDate, endDate)
    }

    static func trailingWeeksFromEndOfToday(_ numberOfWeeks: Int) -> DateRange {
        let endDate = Calendar.current.endOfDay(for: .now)

        guard let startDate = Calendar.current.date(byAdding: .weekOfYear, value: -numberOfWeeks, to: endDate) else {
            return DateRange(endDate, endDate)
        }
        return DateRange(startDate, endDate)
    }

    static func trailingWeeksFromStartOfWeek(_ numberOfWeeks: Int) -> DateRange {
        guard
            let endDate = Calendar.current.startOfWeek(for: .now),
            let startDate = Calendar.current.date(byAdding: .weekOfYear, value: -numberOfWeeks, to: endDate)
        else {
            return DateRange(.now, .now)
        }
        return DateRange(startDate, endDate)
    }

    static func trailingMonthsFromNow(_ numberOfMonths: Int) -> DateRange {
        let endDate = Date.now

        guard let startDate = Calendar.current.date(byAdding: .month, value: -numberOfMonths, to: endDate) else {
            return DateRange(endDate, endDate)
        }

        return DateRange(startDate, endDate)
    }

    static func trailingMonthsFromStartOfWeek(_ numberOfMonths: Int) -> DateRange {
        guard
            let endDate = Calendar.current.startOfWeek(for: .now),
            let startDate = Calendar.current.date(byAdding: .month, value: -numberOfMonths, to: endDate)
        else {
            return DateRange(.now, .now)
        }

        return DateRange(startDate, endDate)
    }

    static func trailingMonthsFromMonthsFromNow(monthsFromNow: Int, numberOfMonths: Int) -> DateRange {
        guard
            let endDate = Calendar.current.date(byAdding: .month, value: -monthsFromNow, to: .now),
            let startDate = Calendar.current.date(byAdding: .month, value: -numberOfMonths, to: endDate)
        else {
            return DateRange(.now, .now)
        }

        return DateRange(startDate, endDate)
    }

    static func trailingMonths(from date: Date, numberOfMonths: Int) -> DateRange {
        guard let startDate = Calendar.current.date(byAdding: .month, value: -numberOfMonths, to: date) else {
            return DateRange(date, date)
        }

        return DateRange(startDate, date)
    }

    static func trailingMonthsFromNowSleepStartDate(_ numberOfMonths: Int) -> DateRange {
        let endDate = Date.now
        let startDate = Calendar.current.sleepStartDate(previousMonths: numberOfMonths, endDate: endDate)
        return DateRange(startDate, endDate)
    }

    static func trailingMonthsFromMonthsFromNowSleepStartDate(monthsFromNow: Int, numberOfMonths: Int) -> DateRange {
        guard let endDate = Calendar.current.date(byAdding: .month, value: -monthsFromNow, to: .now) else {
            return DateRange(.now, .now)
        }

        let startDate = Calendar.current.sleepStartDate(previousMonths: numberOfMonths, endDate: endDate)
        return DateRange(startDate, endDate)
    }

    static func trailingYearsFromNow(_ numberOfYears: Int) -> DateRange {
        let endDate = Date.now

        guard let startDate = Calendar.current.date(byAdding: .year, value: -numberOfYears, to: endDate) else {
            return DateRange(endDate, endDate)
        }

        return DateRange(startDate, endDate)
    }
}
