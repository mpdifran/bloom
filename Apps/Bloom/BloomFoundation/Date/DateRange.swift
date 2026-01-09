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

  func extendToEndOfDay() -> DateRange {
    DateRange(
      start,
      Calendar.current.endOfDay(for: end)
    )
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

  static func fromDateToStartOfToday(_ date: Date) -> DateRange {
    let endDate = Calendar.current.startOfDay(for: .now)
    return DateRange(date, endDate)
  }

  static func fromDateToNow(_ date: Date) -> DateRange {
    return DateRange(date, .now)
  }

  static func duringDay(_ date: Date) -> DateRange {
    let startOfDay = Calendar.current.startOfDay(for: date)
    let endOfDay = Calendar.current.endOfDay(for: date)
    return DateRange(startOfDay, endOfDay)
  }

  static func startOfMonthToNow() -> DateRange {
    let endDate = Date.now
    guard let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: endDate)) else {
        return DateRange(endDate, endDate)
    }
    return DateRange(startOfMonth, endDate)
  }

  static func startOfYearToNow() -> DateRange {
    let endDate = Date.now
    guard let startOfYear = Calendar.current.date(from: Calendar.current.dateComponents([.year], from: endDate)) else {
        return DateRange(endDate, endDate)
    }
    return DateRange(startOfYear, endDate)
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
    let normalizedStart = Calendar.current.startOfDay(for: startDate)
    return DateRange(normalizedStart, endDate)
  }

  static func trailingDaysFromStartOfToday(_ numberOfDays: Int) -> DateRange {
    let endDate = Calendar.current.startOfDay(for: .now)

    guard let startDate = Calendar.current.date(byAdding: .day, value: -numberOfDays, to: endDate) else {
      return DateRange(endDate, endDate)
    }
    return DateRange(startDate, endDate)
  }

  static func trailingDaysFromEndOfYesterday(_ numberOfDays: Int) -> DateRange {
    guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now) else {
      return DateRange(.now, .now)
    }
    let endDate = Calendar.current.endOfDay(for: yesterday)

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
    let normalizedStart = Calendar.current.startOfDay(for: startDate)
    return DateRange(normalizedStart, endDate)
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
    let normalizedStart = Calendar.current.startOfDay(for: startDate)
    return DateRange(normalizedStart, endDate)
  }

  static func trailingMonthsFromEndOfToday(_ numberOfMonths: Int) -> DateRange {
    let endDate = Calendar.current.endOfDay(for: .now)

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
    let normalizedStart = Calendar.current.startOfDay(for: startDate)
    return DateRange(normalizedStart, endDate)
  }
  
  static func specificYear(_ yearsFromNow: Int) -> DateRange {
    let now = Date.now
    guard let targetYear = Calendar.current.date(byAdding: .year, value: -yearsFromNow, to: now) else {
      return DateRange(now, now)
    }
    
    let yearComponents = Calendar.current.dateComponents([.year], from: targetYear)
    guard let startOfYear = Calendar.current.date(from: yearComponents) else {
      return DateRange(now, now)
    }
    
    var endComponents = yearComponents
    endComponents.month = 12
    endComponents.day = 31
    endComponents.hour = 23
    endComponents.minute = 59
    endComponents.second = 59
    
    guard let endOfYear = Calendar.current.date(from: endComponents) else {
      return DateRange(startOfYear, startOfYear)
    }
    
    return DateRange(startOfYear, endOfYear)
  }
  
  static func currentYear() -> DateRange {
    return specificYear(0)
  }
}

// MARK: Biological Age Ranges

public extension DateRange {
  
  static func previousPeriod(from dateRange: DateRange, days: Int) -> DateRange {
    let periodLength = TimeInterval(days * 24 * 60 * 60)
    let previousEnd = dateRange.start
    let previousStart = previousEnd.addingTimeInterval(-periodLength)
    return DateRange(previousStart, previousEnd)
  }
  
  static func previousWeek(from dateRange: DateRange) -> DateRange {
    return previousPeriod(from: dateRange, days: 7)
  }
  
  static func previous30Days(from date: Date) -> DateRange {
    let previousEnd = date.addingTimeInterval(-30 * 24 * 60 * 60)
    let previousStart = previousEnd.addingTimeInterval(-30 * 24 * 60 * 60)
    return DateRange(previousStart, previousEnd)
  }
}

// MARK: Windows

public extension DateRange {

  static func window(around date: Date, numberOfDays: Int) -> DateRange {
    guard
      let startDate = Calendar.current.date(byAdding: .day, value: -numberOfDays, to: date),
      let endDate = Calendar.current.date(byAdding: .day, value: numberOfDays, to: date)
    else {
      return DateRange(date, date)
    }
    return DateRange(startDate, endDate)
  }
}
