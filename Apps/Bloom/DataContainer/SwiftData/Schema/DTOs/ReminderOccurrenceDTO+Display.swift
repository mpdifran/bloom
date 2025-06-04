//
//  ReminderOccurrenceDTO+Display.swift
//  Bloom
//
//  Created by Assistant on 2025-06-04.
//

import Foundation

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
    
    // Get today's completion records sorted by completion time
    let todaysCompletions = completionRecords
      .filter { calendar.isDate($0.completedDate, inSameDayAs: today) }
      .sorted { $0.completedDate < $1.completedDate }
    
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
    
    // Create displays based on completion count
    var displays: [ReminderOccurrenceDisplay] = []
    
    for (index, pair) in occurrenceTimePairs.enumerated() {
      let (occurrence, scheduledTime) = pair
      
      // Check if this occurrence is completed based on completion count
      let isCompleted = index < todaysCompletions.count
      
      // Get the specific completion date for this occurrence (if completed)
      let completionDate = isCompleted ? todaysCompletions[index].completedDate : nil
      
      // Show if completed or if it's the next uncompleted occurrence
      if isCompleted || index == todaysCompletions.count {
        displays.append(ReminderOccurrenceDisplay(
          reminder: self,
          occurrence: occurrence,
          scheduledTime: scheduledTime,
          isCompleted: isCompleted,
          completionDate: completionDate
        ))
      }
    }
    
    return displays
  }
}

public extension ReminderOccurrenceDTO {
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