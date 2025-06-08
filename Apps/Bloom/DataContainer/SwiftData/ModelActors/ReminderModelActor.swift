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
    occurrenceID: String? = nil,
    completionDate: Date = Date()
  ) throws -> ReminderCompletionRecordDTO? {
    let descriptor = FetchDescriptor<Reminder>(
      predicate: #Predicate<Reminder> { reminder in
        reminder.id == reminderID
      }
    )
    guard let reminder = try context.fetch(descriptor).first else { return nil }
    
    var occurrence: ReminderOccurrence? = nil
    if let occurrenceID = occurrenceID {
      occurrence = reminder.occurrences?.first { $0.id == occurrenceID }
    }
    
    let completionRecord = ReminderCompletionRecord(
      reminder: reminder,
      occurrence: occurrence,
      completedDate: completionDate
    )
    context.insert(completionRecord)
    
    try context.save()
    return completionRecord.asDTO()
  }
  
  func markReminderUncompleted(
    reminderID: String,
    occurrenceID: String? = nil,
    completionDate: Date = Date()
  ) throws {
    let calendar = Calendar.current
    let targetDay = calendar.startOfDay(for: completionDate)
    
    let descriptor = FetchDescriptor<ReminderCompletionRecord>(
      predicate: #Predicate<ReminderCompletionRecord> { record in
        if let occurrenceID = occurrenceID {
          return record.reminder?.id == reminderID && record.occurrence?.id == occurrenceID
        } else {
          return record.reminder?.id == reminderID
        }
      }
    )
    
    let completionRecords = try context.fetch(descriptor)
    
    // Find completion records from the target date
    let recordsToDelete = completionRecords.filter { record in
      calendar.isDate(record.completedDate, inSameDayAs: targetDay)
    }
    
    // If we have an occurrenceID, only delete the first matching record
    // Otherwise, delete all records from that day (old behavior)
    if occurrenceID != nil && !recordsToDelete.isEmpty {
      // Delete only the most recent completion for this specific occurrence
      if let recordToDelete = recordsToDelete.sorted(by: { $0.completedDate > $1.completedDate }).first {
        context.delete(recordToDelete)
      }
    } else {
      // Delete all completion records from that day
      for record in recordsToDelete {
        context.delete(record)
      }
    }
    
    try context.save()
  }
}
