//
//  ModelContext+Reminders.swift
//  Bloom
//
//  Created by Assistant on 2025-06-04.
//

import SwiftData

public extension ModelContext {
  
  func fetchAllReminders() throws -> [Reminder] {
    let descriptor = FetchDescriptor<Reminder>(
      sortBy: [SortDescriptor(\Reminder.modifiedDate, order: .reverse)]
    )
    return try fetch(descriptor)
  }
  
  func fetchReminder(withID id: String) throws -> Reminder? {
    let descriptor = FetchDescriptor<Reminder>(
      predicate: #Predicate<Reminder> { reminder in
        reminder.id == id
      }
    )
    return try fetch(descriptor).first
  }
  
  func fetchRemindersWithOccurrenceToday() throws -> [Reminder] {
    let allReminders = try fetchAllReminders()
    let calendar = Calendar.current
    let today = Date()
    let todayComponents = calendar.dateComponents([.weekday, .day, .month], from: today)
    
    return allReminders.filter { reminder in
      guard let occurrences = reminder.occurrences, !occurrences.isEmpty else {
        return false
      }
      
      return occurrences.contains { occurrence in
        switch occurrence.cadenceType {
        case .daily:
          // Daily reminders always occur
          return true
          
        case .weekly:
          // Check if today's weekday is in the selected days
          guard let todayWeekday = todayComponents.weekday,
                let daysOfWeek = occurrence.daysOfWeek else {
            return false
          }
          // Convert from 1-based (Calendar) to 0-based (our storage)
          let todayIndex = todayWeekday - 1
          return daysOfWeek.contains(todayIndex)
          
        case .monthly:
          // Check if today's day of month matches
          guard let todayDay = todayComponents.day,
                let dayOfMonth = occurrence.dayOfMonth else {
            return false
          }
          return todayDay == dayOfMonth
          
        case .yearly:
          // Check if today's month and day match
          guard let todayMonth = todayComponents.month,
                let todayDay = todayComponents.day,
                let monthOfYear = occurrence.monthOfYear,
                let dayOfYear = occurrence.dayOfYear else {
            return false
          }
          return todayMonth == monthOfYear && todayDay == dayOfYear
        }
      }
    }
  }
  
  func deleteReminder(_ reminder: Reminder) {
    delete(reminder)
  }
}