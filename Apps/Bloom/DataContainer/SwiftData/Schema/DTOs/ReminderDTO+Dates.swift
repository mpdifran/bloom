//
//  ReminderDTO+Dates.swift
//  Bloom
//
//  Created by Assistant on 2025-06-04.
//

import Foundation

public extension ReminderDTO {
  
  /// Returns the next scheduled notification date for this reminder
  var nextNotificationDate: Date? {
    let now = Date()
    var earliestNext: Date?
    
    for occurrence in occurrences {
      let nextDate = occurrence.calculateNextNotificationDate(from: now)
      if let next = nextDate {
        if let earliest = earliestNext {
          if next < earliest {
            earliestNext = next
          }
        } else {
          earliestNext = next
        }
      }
    }
    
    return earliestNext
  }
  
  /// Returns the last missed notification date (for overdue status)
  var lastMissedNotificationDate: Date? {
    let now = Date()
    var latestMissed: Date?
    
    for occurrence in occurrences {
      let missedDate = occurrence.calculateLastMissedDate(before: now, completionRecords: completionRecords)
      if let missed = missedDate {
        if let latest = latestMissed {
          if missed > latest {
            latestMissed = missed
          }
        } else {
          latestMissed = missed
        }
      }
    }
    
    return latestMissed
  }
  
  /// Returns true if this reminder has a notification scheduled for today (regardless of time)
  var hasNotificationToday: Bool {
    let calendar = Calendar.current
    let now = Date()
    let todayComponents = calendar.dateComponents([.weekday, .day, .month], from: now)
    
    return occurrences.contains { occurrence in
      switch occurrence.cadenceType {
      case .daily:
        // Daily reminders always have notifications today
        return true
        
      case .weekly:
        // Check if today's weekday is in the selected days
        guard let todayWeekday = todayComponents.weekday,
              let daysOfWeek = occurrence.daysOfWeek else { return false }
        return daysOfWeek.contains(todayWeekday)
        
      case .monthly:
        // Check if today's day of month matches
        guard let todayDay = todayComponents.day,
              let dayOfMonth = occurrence.dayOfMonth else { return false }
        return todayDay == dayOfMonth
        
      case .yearly:
        // Check if today's month and day match
        guard let todayMonth = todayComponents.month,
              let todayDay = todayComponents.day,
              let monthOfYear = occurrence.monthOfYear,
              let dayOfYear = occurrence.dayOfYear else { return false }
        return todayMonth == monthOfYear && todayDay == dayOfYear
      }
    }
  }
  
  /// Returns true if this reminder had a notification scheduled for today that has already passed
  func isOverdueToday(completionRecords: [ReminderCompletionRecordDTO]) -> Bool {
    // If completed today, it's not overdue
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let isCompletedToday = completionRecords.contains { record in
      calendar.isDate(record.completedDate, inSameDayAs: today)
    }
    
    if isCompletedToday { return false }
    
    // Check if any occurrence had a notification scheduled for today that has passed
    let now = Date()
    
    for occurrence in occurrences {
      switch occurrence.cadenceType {
      case .daily:
        // For daily reminders, check if the time today has passed
        let hour = Int(occurrence.timeOfDay) / 3600
        let minute = (Int(occurrence.timeOfDay) % 3600) / 60
        
        if let todayTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now),
           todayTime < now {
          return true
        }
        
      case .weekly:
        // For weekly reminders, check if today is a scheduled day and time has passed
        guard let daysOfWeek = occurrence.daysOfWeek,
              let todayWeekday = calendar.dateComponents([.weekday], from: now).weekday,
              daysOfWeek.contains(todayWeekday) else { continue }
        
        let hour = Int(occurrence.timeOfDay) / 3600
        let minute = (Int(occurrence.timeOfDay) % 3600) / 60
        
        if let todayTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now),
           todayTime < now {
          return true
        }
        
      case .monthly:
        // For monthly reminders, check if today is the scheduled day and time has passed
        guard let dayOfMonth = occurrence.dayOfMonth,
              let todayDay = calendar.dateComponents([.day], from: now).day,
              dayOfMonth == todayDay else { continue }
        
        let hour = Int(occurrence.timeOfDay) / 3600
        let minute = (Int(occurrence.timeOfDay) % 3600) / 60
        
        if let todayTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now),
           todayTime < now {
          return true
        }
        
      case .yearly:
        // For yearly reminders, check if today is the scheduled month/day and time has passed
        guard let monthOfYear = occurrence.monthOfYear,
              let dayOfYear = occurrence.dayOfYear else { continue }
        
        let todayComponents = calendar.dateComponents([.month, .day], from: now)
        guard monthOfYear == todayComponents.month,
              dayOfYear == todayComponents.day else { continue }
        
        let hour = Int(occurrence.timeOfDay) / 3600
        let minute = (Int(occurrence.timeOfDay) % 3600) / 60
        
        if let todayTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now),
           todayTime < now {
          return true
        }
      }
    }
    
    return false
  }
  
  /// Returns today's completion date if this reminder was completed today
  var todaysCompletionDate: Date? {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    
    return completionRecords
      .first { record in
        calendar.isDate(record.completedDate, inSameDayAs: today)
      }?
      .completedDate
  }
}

public extension ReminderOccurrenceDTO {
  
  /// Calculates the next notification date for this occurrence from the given date
  func calculateNextNotificationDate(from date: Date) -> Date? {
    let calendar = Calendar.current
    let hour = Int(timeOfDay) / 3600
    let minute = (Int(timeOfDay) % 3600) / 60
    
    switch cadenceType {
    case .daily:
      var components = calendar.dateComponents([.year, .month, .day], from: date)
      components.hour = hour
      components.minute = minute
      
      if let todayTime = calendar.date(from: components), todayTime > date {
        return todayTime
      } else {
        return calendar.date(byAdding: .day, value: 1, to: calendar.date(from: components)!)
      }
      
    case .weekly:
      guard let daysOfWeek = daysOfWeek, !daysOfWeek.isEmpty else { return nil }
      
      var nextDates: [Date] = []
      
      for dayOfWeek in daysOfWeek {
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        components.weekday = dayOfWeek // Already 1-based (1=Sunday, 7=Saturday)
        components.hour = hour
        components.minute = minute
        
        if let thisWeekDate = calendar.date(from: components) {
          if thisWeekDate > date {
            nextDates.append(thisWeekDate)
          } else {
            // Next week
            if let nextWeekDate = calendar.date(byAdding: .weekOfYear, value: 1, to: thisWeekDate) {
              nextDates.append(nextWeekDate)
            }
          }
        }
      }
      
      return nextDates.min()
      
    case .monthly:
      guard let dayOfMonth = dayOfMonth else { return nil }
      
      var components = calendar.dateComponents([.year, .month], from: date)
      components.day = dayOfMonth
      components.hour = hour
      components.minute = minute
      
      if let thisMonthDate = calendar.date(from: components), thisMonthDate > date {
        return thisMonthDate
      } else {
        components.month = (components.month ?? 1) + 1
        return calendar.date(from: components)
      }
      
    case .yearly:
      guard let monthOfYear = monthOfYear,
            let dayOfYear = dayOfYear else { return nil }
      
      var components = calendar.dateComponents([.year], from: date)
      components.month = monthOfYear
      components.day = dayOfYear
      components.hour = hour
      components.minute = minute
      
      if let thisYearDate = calendar.date(from: components), thisYearDate > date {
        return thisYearDate
      } else {
        components.year = (components.year ?? 2025) + 1
        return calendar.date(from: components)
      }
    }
  }
  
  /// Calculates the last missed notification date for this occurrence before the given date
  func calculateLastMissedDate(before date: Date, completionRecords: [ReminderCompletionRecordDTO]) -> Date? {
    let calendar = Calendar.current
    let hour = Int(timeOfDay) / 3600
    let minute = (Int(timeOfDay) % 3600) / 60
    
    // Check if there's a completion record for today
    let today = calendar.startOfDay(for: date)
    let hasCompletionToday = completionRecords.contains { record in
      calendar.isDate(record.completedDate, inSameDayAs: today)
    }
    
    if hasCompletionToday {
      return nil // Not overdue if completed today
    }
    
    switch cadenceType {
    case .daily:
      var components = calendar.dateComponents([.year, .month, .day], from: date)
      components.hour = hour
      components.minute = minute
      
      if let todayTime = calendar.date(from: components), todayTime < date {
        return todayTime
      }
      return nil
      
    case .weekly:
      guard let daysOfWeek = daysOfWeek, !daysOfWeek.isEmpty else { return nil }
      
      for dayOfWeek in daysOfWeek.sorted().reversed() {
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        components.weekday = dayOfWeek // Already 1-based (1=Sunday, 7=Saturday)
        components.hour = hour
        components.minute = minute
        
        if let weekDate = calendar.date(from: components), weekDate < date {
          return weekDate
        }
      }
      return nil
      
    case .monthly:
      guard let dayOfMonth = dayOfMonth else { return nil }
      
      var components = calendar.dateComponents([.year, .month], from: date)
      components.day = dayOfMonth
      components.hour = hour
      components.minute = minute
      
      if let monthDate = calendar.date(from: components), monthDate < date {
        return monthDate
      }
      return nil
      
    case .yearly:
      guard let monthOfYear = monthOfYear,
            let dayOfYear = dayOfYear else { return nil }
      
      var components = calendar.dateComponents([.year], from: date)
      components.month = monthOfYear
      components.day = dayOfYear
      components.hour = hour
      components.minute = minute
      
      if let yearDate = calendar.date(from: components), yearDate < date {
        return yearDate
      }
      return nil
    }
  }
}