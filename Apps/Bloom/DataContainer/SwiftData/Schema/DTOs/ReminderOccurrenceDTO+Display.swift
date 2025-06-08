//
//  ReminderOccurrenceDTO+Display.swift
//  Bloom
//
//  Created by Assistant on 2025-06-04.
//

import Foundation
import BloomFoundation

public struct ReminderOccurrenceDisplay: Identifiable {
  public let id: String
  public let reminder: ReminderDTO
  public let occurrence: ReminderOccurrenceDTO
  public let scheduledTime: Date
  public let isCompleted: Bool
  public let completionDate: Date?
  
  public init(
    reminder: ReminderDTO,
    occurrence: ReminderOccurrenceDTO,
    scheduledTime: Date,
    isCompleted: Bool,
    completionDate: Date? = nil
  ) {
    self.id = "\(reminder.id)-\(occurrence.id)-\(scheduledTime.timeIntervalSince1970)"
    self.reminder = reminder
    self.occurrence = occurrence
    self.scheduledTime = scheduledTime
    self.isCompleted = isCompleted
    self.completionDate = completionDate
  }
}

public extension ReminderDTO {
  /// Returns display items for today's occurrences, taking into account completions
  func todaysOccurrenceDisplays() -> [ReminderOccurrenceDisplay] {
    let calendar = Calendar.current
    let now = Date()
    let today = calendar.startOfDay(for: now)
    
    // Get today's completion records
    let todaysCompletions = completionRecords
      .filter { calendar.isDate($0.completedDate, inSameDayAs: today) }
    
    // Get all occurrences that are scheduled for today with their times
    var occurrenceTimePairs: [(ReminderOccurrenceDTO, Date)] = []
    
    for occurrence in occurrences {
      let scheduledTimes = occurrence.scheduledTimesToday()
      for scheduledTime in scheduledTimes {
        occurrenceTimePairs.append((occurrence, scheduledTime))
      }
    }
    
    // Sort by scheduled time
    occurrenceTimePairs.sort { $0.1 < $1.1 }
    
    // Create displays checking specific occurrence completions
    var displays: [ReminderOccurrenceDisplay] = []
    
    // Track which occurrences have been shown as uncompleted
    var hasShownUncompleted = false
    
    for pair in occurrenceTimePairs {
      let (occurrence, scheduledTime) = pair
      
      // Check if this specific occurrence is completed
      let isCompleted = todaysCompletions.contains { completion in
        completion.occurrenceID == occurrence.id
      }
      
      // Get the specific completion date for this occurrence (if completed)
      let completionDate = todaysCompletions.first { $0.occurrenceID == occurrence.id }?.completedDate
      
      // Check if the notification time has passed
      let notificationTimePassed = scheduledTime <= now
      
      // Show if:
      // 1. Already completed, OR
      // 2. First uncompleted occurrence, OR
      // 3. Notification time has passed (to show multiple occurrences when their times have elapsed)
      if isCompleted || !hasShownUncompleted || notificationTimePassed {
        displays.append(ReminderOccurrenceDisplay(
          reminder: self,
          occurrence: occurrence,
          scheduledTime: scheduledTime,
          isCompleted: isCompleted,
          completionDate: completionDate
        ))
        
        if !isCompleted {
          hasShownUncompleted = true
        }
      }
    }
    
    return displays
  }
}

public extension ReminderOccurrenceDTO {
  /// Computed property that converts timeOfDay to a Date
  var time: Date {
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: Date())
    return startOfDay.addingTimeInterval(timeOfDay)
  }
  
  /// Returns a human-readable description of this occurrence's cadence and time
  var cadenceDescription: String {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.dateStyle = .none
    
    let timeString = formatter.string(from: time)
    
    switch cadenceType {
    case .daily:
      return "Every day at \(timeString)"
      
    case .weekly:
      guard let days = daysOfWeek, !days.isEmpty else {
        return "Weekly at \(timeString)"
      }

      let sortedDays = days.sorted()
      
      // Check if all days are weekdays (Monday-Friday, which are 2-6 in iOS)
      let weekdays = Set([2, 3, 4, 5, 6])
      if Set(sortedDays) == weekdays {
        return "Weekdays at \(timeString)"
      }
      
      // Check if all days are weekends (Saturday-Sunday, which are 7 and 1 in iOS)
      let weekends = Set([1, 7])
      if Set(sortedDays) == weekends {
        return "Weekends at \(timeString)"
      }
      
      let dayNames = sortedDays.compactMap { Calendar.current.weekdaySymbols[safe: $0 - 1] }
      
      if dayNames.count == 1 {
        return "Every \(dayNames[0]) at \(timeString)"
      } else if dayNames.count == 2 {
        return "Every \(dayNames[0]) and \(dayNames[1]) at \(timeString)"
      } else {
        let allButLast = dayNames.dropLast()
        let commaSeparated = allButLast.joined(separator: ", ")
        return "Every \(commaSeparated), and \(dayNames.last!) at \(timeString)"
      }
      
    case .monthly:
      guard let day = dayOfMonth else {
        return "Monthly at \(timeString)"
      }
      
      let ordinal = NumberFormatter.ordinal.string(from: NSNumber(value: day)) ?? "\(day)"
      return "Every month on the \(ordinal) at \(timeString)"
      
    case .yearly:
      guard let month = monthOfYear, let day = dayOfYear else {
        return "Yearly at \(timeString)"
      }
      
      let monthName = Calendar.current.monthSymbols[safe: month - 1] ?? ""
      let ordinal = NumberFormatter.ordinal.string(from: NSNumber(value: day)) ?? "\(day)"
      return "Every year on \(monthName) \(ordinal) at \(timeString)"
    }
  }
  
  /// Returns all scheduled times for today for this occurrence
  func scheduledTimesToday() -> [Date] {
    let calendar = Calendar.current
    let now = Date()
    let today = calendar.startOfDay(for: now)
    
    switch cadenceType {
    case .daily:
      // Daily reminders occur once per day at the specified time
      let hour = Int(timeOfDay) / 3600
      let minute = (Int(timeOfDay) % 3600) / 60
      
      if let scheduledTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today) {
        return [scheduledTime]
      }
      return []
      
    case .weekly:
      // Check if today is one of the scheduled days
      guard let daysOfWeek = daysOfWeek,
            let todayWeekday = calendar.dateComponents([.weekday], from: now).weekday,
            daysOfWeek.contains(todayWeekday) else {
        return []
      }
      
      let hour = Int(timeOfDay) / 3600
      let minute = (Int(timeOfDay) % 3600) / 60
      
      if let scheduledTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today) {
        return [scheduledTime]
      }
      return []
      
    case .monthly:
      // Check if today is the scheduled day of month
      guard let dayOfMonth = dayOfMonth,
            let todayDay = calendar.dateComponents([.day], from: now).day,
            dayOfMonth == todayDay else {
        return []
      }
      
      let hour = Int(timeOfDay) / 3600
      let minute = (Int(timeOfDay) % 3600) / 60
      
      if let scheduledTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today) {
        return [scheduledTime]
      }
      return []
      
    case .yearly:
      // Check if today is the scheduled month and day
      guard let monthOfYear = monthOfYear,
            let dayOfYear = dayOfYear else {
        return []
      }
      
      let todayComponents = calendar.dateComponents([.month, .day], from: now)
      guard monthOfYear == todayComponents.month,
            dayOfYear == todayComponents.day else {
        return []
      }
      
      let hour = Int(timeOfDay) / 3600
      let minute = (Int(timeOfDay) % 3600) / 60
      
      if let scheduledTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today) {
        return [scheduledTime]
      }
      return []
    }
  }
}