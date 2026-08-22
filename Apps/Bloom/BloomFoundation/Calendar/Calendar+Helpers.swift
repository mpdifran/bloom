//
//  Calendar+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-25.
//

import Foundation

public extension Calendar {
  enum Weekday: Int, Sendable {
    case sunday = 1
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday

    /// The weekday's name in the user's language.
    ///
    /// Taken from `Calendar.weekdaySymbols` rather than hardcoded English: the system already has
    /// these translated for every locale, and the raw value matches Calendar's 1-based numbering.
    public var name: String {
      let symbols = Calendar.current.weekdaySymbols
      let index = rawValue - 1

      guard symbols.indices.contains(index) else { return "" }

      return symbols[index]
    }
  }

  enum TimeOfDay: CaseIterable, Identifiable, Sendable {
    public var id: Self { self }

    case morning
    case afternoon
    case evening
    case overnight

    public var name: String {
      switch self {
      case .morning:
        String(localized: "Morning", bundle: Bundle.bloomFoundation, comment: "Part of the day")
      case .afternoon:
        String(localized: "Afternoon", bundle: Bundle.bloomFoundation, comment: "Part of the day")
      case .evening:
        String(localized: "Evening", bundle: Bundle.bloomFoundation, comment: "Part of the day")
      case .overnight:
        String(localized: "Overnight", bundle: Bundle.bloomFoundation, comment: "Part of the day")
      }
    }

    /// The hours this part of the day covers, formatted for the user's locale.
    ///
    /// Built from real times rather than written out: "6am - 12pm" is a US 12-hour format, and
    /// German, French and Dutch users expect "06:00 - 12:00".
    public var summary: String {
      let (start, end) = switch self {
      case .morning: (6, 12)
      case .afternoon: (12, 18)
      case .evening: (18, 24)
      case .overnight: (0, 6)
      }

      return "\(Self.formatted(hour: start)) - \(Self.formatted(hour: end))"
    }

    private static func formatted(hour: Int) -> String {
      var components = DateComponents()
      components.hour = hour == 24 ? 0 : hour

      guard let date = Calendar.current.date(from: components) else { return "" }

      return date.formatted(.dateTime.hour())
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

  func morningTime(for date: Date) -> Date? {
    var components = dateComponents([.year, .month, .day], from: date)
    components.hour = 5
    components.minute = 0
    components.second = 0
    return self.date(from: components)
  }

  func eveningTime(for date: Date) -> Date? {
    var components = dateComponents([.year, .month, .day], from: date)
    components.hour = 17
    components.minute = 0
    components.second = 0
    return self.date(from: components)
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

  func startOfYear(for date: Date) -> Date? {
    var components = self.dateComponents([.year], from: date)
    components.month = 1
    components.day = 1
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

  func asyncIterate(dateRange: DateRange, by dateComponents: DateComponents, iterator: (Date) async -> Void) async {
    guard dateRange.end > dateRange.start else { return }

    var currentDate = dateRange.start

    while currentDate <= dateRange.end {
      await iterator(currentDate)

      if let nextDate = date(byAdding: dateComponents, to: currentDate) {
        currentDate = nextDate
      } else {
        break
      }
    }
  }
}

public extension Calendar {

  func dateCollection(for dateRange: DateRange) -> [Date] {
    var dates = [Date]()
    iterate(dateRange: dateRange, by: DateComponents(day: 1)) { date in
      dates.append(date)
    }
    return dates
  }
}
