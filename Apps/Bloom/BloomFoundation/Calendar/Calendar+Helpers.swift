//
//  Calendar+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-25.
//

import Foundation

public extension Calendar {
    enum Weekday: Int {
        case sunday = 1
        case monday
        case tuesday
        case wednesday
        case thursday
        case friday
        case saturday

        public var name: String {
            switch self {
            case .sunday:
                "Sunday"
            case .monday:
                "Monday"
            case .tuesday:
                "Tuesday"
            case .wednesday:
                "Wednesday"
            case .thursday:
                "Thursday"
            case .friday:
                "Friday"
            case .saturday:
                "Saturday"
            }
        }
    }

    enum TimeOfDay: CaseIterable, Identifiable {
        public var id: Self { self }

        case morning
        case afternoon
        case evening
        case overnight

        public var name: String {
            switch self {
            case .morning:
                "Morning"
            case .afternoon:
                "Afternoon"
            case .evening:
                "Evening"
            case .overnight:
                "Overnight"
            }
        }

        public var summary: String {
            switch self {
            case .morning:
                "6am - 12pm"
            case .afternoon:
                "12pm - 6pm"
            case .evening:
                "6pm - 12am"
            case .overnight:
                "12am - 6am"
            }
        }
    }
}

public extension Calendar {

    func weekday(for date: Date) -> Weekday? {
        guard let weekday = dateComponents([.weekday], from: date).weekday else { return nil }

        return Weekday(rawValue: weekday)
    }

    func weekOfYear(for date: Date) -> Int? {
        dateComponents([.weekOfYear], from: date).weekOfYear
    }

    func isMorning(date: Date) -> Bool {
        guard let hour = dateComponents([.hour], from: date).hour else { return false }

        return hour >= 5 && hour < 11
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
        let startOfNextDay = startOfDay(for: nextDay)
        return self.date(byAdding: .second, value: -1, to: startOfNextDay) ?? startOfNextDay
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

    func startOfMonth(for date: Date) -> Date? {
        startOfDayInMonth(for: date, day: 1)
    }

    func startOfDayInMonth(for date: Date, day: Int) -> Date? {
        var components = self.dateComponents([.year, .month], from: date)
        components.day = day
        return self.date(from: components)
    }

    func mondayMorning(for date: Date) -> Date? {
        var components = self.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        components.weekday = 2
        components.hour = 9

        // Is there a more clever way of doing this?

        guard let result = self.date(from: components) else {
            return nil
        }

        if result > date {
            return self.date(byAdding: .weekOfYear, value: -1, to: result)
        }
        return result
    }

    func nextMondayMorning(for date: Date) -> Date? {
        guard let nextWeek = self.date(byAdding: .weekOfYear, value: 1, to: date) else { return nil }

        return self.mondayMorning(for: nextWeek)
    }

    func mondayMorningMidnight(for date: Date) -> Date? {
        guard let monday = mondayMorning(for: date) else { return nil }

        let components = self.dateComponents([.year, .month, .day], from: monday)

        return self.date(from: components)
    }

    func nextMondayMorningMidnight(for date: Date) -> Date? {
        guard let monday = nextMondayMorning(for: date) else { return nil }

        let components = self.dateComponents([.year, .month, .day], from: monday)

        return self.date(from: components)
    }

    func applyHourMinuteSecond(to toDate: Date, from fromDate: Date) -> Date? {
        let components = self.dateComponents([.hour, .minute, .second], from: fromDate)

        var currentComponents = self.dateComponents([.year, .month, .day], from: toDate)

        currentComponents.hour = components.hour
        currentComponents.minute = components.minute
        currentComponents.second = components.second

        return self.date(from: currentComponents)
    }

    func timeOfDay(for date: Date) -> TimeOfDay {
        let hour = Calendar.current.component(.hour, from: date)

        if hour < 6 {
            return .overnight
        } else if hour < 12 {
            return .morning
        } else if hour < 18 {
            return .afternoon
        } else {
            return .evening
        }
    }
}

public extension Calendar {

    func iterate(dateRange: DateRange, by dateComponents: DateComponents, iterator: (Date) -> Void) {
        guard dateRange.end > dateRange.start else { return }

        var currentDate = dateRange.start

        while currentDate <= dateRange.end {
            iterator(currentDate)

            if let nextDate = date(byAdding: dateComponents, to: currentDate) {
                currentDate = nextDate
            } else {
                break
            }
        }
    }
}
