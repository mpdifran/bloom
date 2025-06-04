//
//  ReminderModelActor.swift
//  Bloom
//
//  Created by Assistant on 2025-06-04.
//

import Foundation
import SwiftData

@ModelActor
public final actor ReminderModelActor: SharedModelActor {
  
  private var context: ModelContext { modelExecutor.modelContext }
}

public extension ReminderModelActor {
  
  func fetchAllReminders() throws -> [ReminderDTO] {
    let descriptor = FetchDescriptor<Reminder>(
      sortBy: [SortDescriptor(\Reminder.modifiedDate, order: .reverse)]
    )
    return try context.fetch(descriptor).map { $0.asDTO() }
  }
  
  func fetchReminder(withID id: String) throws -> ReminderDTO? {
    let descriptor = FetchDescriptor<Reminder>(
      predicate: #Predicate<Reminder> { reminder in
        reminder.id == id
      }
    )
    let reminders = try context.fetch(descriptor)
    return reminders.first?.asDTO()
  }
  
  func fetchRemindersWithOccurrenceToday() throws -> [ReminderDTO] {
    return try context.fetchRemindersWithOccurrenceToday().map { $0.asDTO() }
  }
  
  func createReminder(
    title: String,
    colorHex: String,
    occurrences: [ReminderOccurrence]
  ) throws -> ReminderDTO {
    let reminder = Reminder(
      title: title,
      colorHex: colorHex,
      occurrences: occurrences
    )
    context.insert(reminder)
    try context.save()
    return reminder.asDTO()
  }
  
  func updateReminder(
    withID id: String,
    title: String,
    colorHex: String,
    occurrences: [ReminderOccurrence]
  ) throws -> ReminderDTO? {
    let descriptor = FetchDescriptor<Reminder>(
      predicate: #Predicate<Reminder> { reminder in
        reminder.id == id
      }
    )
    guard let reminder = try context.fetch(descriptor).first else { return nil }
    
    reminder.title = title
    reminder.colorHex = colorHex
    reminder.occurrences = occurrences
    reminder.modifiedDate = Date()
    
    try context.save()
    return reminder.asDTO()
  }
  
  func deleteReminder(withID id: String) throws {
    let descriptor = FetchDescriptor<Reminder>(
      predicate: #Predicate<Reminder> { reminder in
        reminder.id == id
      }
    )
    guard let reminder = try context.fetch(descriptor).first else { return }
    
    context.delete(reminder)
    try context.save()
  }
  
  func markReminderCompleted(
    reminderID: String,
    completionDate: Date = Date()
  ) throws -> ReminderCompletionRecordDTO? {
    let descriptor = FetchDescriptor<Reminder>(
      predicate: #Predicate<Reminder> { reminder in
        reminder.id == reminderID
      }
    )
    guard let reminder = try context.fetch(descriptor).first else { return nil }
    
    let completionRecord = ReminderCompletionRecord(
      reminder: reminder,
      completedDate: completionDate
    )
    context.insert(completionRecord)
    
    try context.save()
    return completionRecord.asDTO()
  }
  
  func markReminderUncompleted(
    reminderID: String,
    completionDate: Date = Date()
  ) throws {
    let calendar = Calendar.current
    let targetDay = calendar.startOfDay(for: completionDate)
    
    let descriptor = FetchDescriptor<ReminderCompletionRecord>(
      predicate: #Predicate<ReminderCompletionRecord> { record in
        record.reminder?.id == reminderID
      }
    )
    
    let completionRecords = try context.fetch(descriptor)
    
    // Find completion records from the target date
    let recordsToDelete = completionRecords.filter { record in
      calendar.isDate(record.completedDate, inSameDayAs: targetDay)
    }
    
    // Delete the completion records
    for record in recordsToDelete {
      context.delete(record)
    }
    
    try context.save()
  }
}
