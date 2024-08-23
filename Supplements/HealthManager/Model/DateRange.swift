//
//  DateRange.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-14.
//

import Foundation

struct DateRange {
    let start: Date
    let end: Date

    init(_ start: Date, _ end: Date) {
        self.start = start
        self.end = end
    }
}

extension DateRange {

    var numberOfDaysInclusive: Int {
        (Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0) + 1
    }
}

// MARK: Start Of Week / Day

extension DateRange {
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
}

// MARK: Trailing Ranges

extension DateRange {
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

    static func trailingDaysFromStartOfWeek(_ numberOfDays: Int) -> DateRange {
        guard
            let endDate = Calendar.current.startOfWeek(for: .now),
            let startDate = Calendar.current.date(byAdding: .day, value: -numberOfDays, to: endDate)
        else {
            return DateRange(.now, .now)
        }
        return DateRange(startDate, endDate)
    }

    static func trailingWeeksFromNow(_ numberOfWeeks: Int) -> DateRange {
        let endDate = Date.now

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
