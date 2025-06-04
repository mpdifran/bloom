//
//  ReminderDTO+NotificationDates.swift
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
        components.weekday = dayOfWeek + 1 // Convert to 1-based
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
        components.weekday = dayOfWeek + 1
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