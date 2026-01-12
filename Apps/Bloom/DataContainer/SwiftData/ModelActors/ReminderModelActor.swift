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
  
  func fetchRemindersWithTrigger(_ triggerType: ReminderTriggerType) throws -> [ReminderDTO] {
    let triggerRawValue = triggerType.rawValue
    let descriptor = FetchDescriptor<Reminder>(
      predicate: #Predicate<Reminder> { reminder in
        reminder.triggerType == triggerRawValue
      }
    )
    return try context.fetch(descriptor).map { $0.asDTO() }
  }
  
  func createReminder(
    title: String,
    colorHex: String,
    triggerType: ReminderTriggerType? = nil,
    occurrences: [ReminderOccurrenceDTO],
    sideEffects: [ReminderSideEffectDTO] = []
  ) throws -> ReminderDTO {
    // Create model instances from DTOs inside the actor
    let occurrenceModels = occurrences.map { dto in
      ReminderOccurrence(
        cadenceType: dto.cadenceType,
        timeOfDay: dto.timeOfDay,
        daysOfWeek: dto.daysOfWeek,
        dayOfMonth: dto.dayOfMonth,
        monthOfYear: dto.monthOfYear,
        dayOfYear: dto.dayOfYear
      )
    }

    let sideEffectModels = sideEffects.compactMap { dto -> ReminderSideEffect? in
      guard let type = dto.type else { return nil }
      return ReminderSideEffect(
        id: dto.id,
        type: type,
        configuration: dto.configuration
      )
    }

    let reminder = Reminder(
      title: title,
      colorHex: colorHex,
      triggerType: triggerType?.rawValue,
      occurrences: occurrenceModels
    )
    reminder.sideEffects = sideEffectModels
    context.insert(reminder)
    try context.save()
    return reminder.asDTO()
  }
  
  func updateReminder(
    withID id: String,
    title: String,
    colorHex: String,
    triggerType: ReminderTriggerType? = nil,
    occurrences: [ReminderOccurrenceDTO],
    sideEffects: [ReminderSideEffectDTO] = []
  ) throws -> ReminderDTO? {
    let descriptor = FetchDescriptor<Reminder>(
      predicate: #Predicate<Reminder> { reminder in
        reminder.id == id
      }
    )
    guard let reminder = try context.fetch(descriptor).first else { return nil }

    // Create model instances from DTOs inside the actor
    let occurrenceModels = occurrences.map { dto in
      ReminderOccurrence(
        cadenceType: dto.cadenceType,
        timeOfDay: dto.timeOfDay,
        daysOfWeek: dto.daysOfWeek,
        dayOfMonth: dto.dayOfMonth,
        monthOfYear: dto.monthOfYear,
        dayOfYear: dto.dayOfYear
      )
    }

    let sideEffectModels = sideEffects.compactMap { dto -> ReminderSideEffect? in
      guard let type = dto.type else { return nil }
      return ReminderSideEffect(
        id: dto.id,
        type: type,
        configuration: dto.configuration
      )
    }

    reminder.title = title
    reminder.colorHex = colorHex
    reminder.triggerType = triggerType?.rawValue
    reminder.occurrences = occurrenceModels
    reminder.sideEffects = sideEffectModels
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
  ) throws -> [SideEffectExecutionResult]? {
    let calendar = Calendar.current
    let targetDay = calendar.startOfDay(for: completionDate)
    
    // Simple predicate to avoid slow type-checking from conditional logic
    let descriptor = FetchDescriptor<ReminderCompletionRecord>(
      predicate: #Predicate<ReminderCompletionRecord> { record in
        record.reminder?.id == reminderID
      }
    )

    var completionRecords = try context.fetch(descriptor)

    // In-memory filter for occurrenceID (if specified)
    if let occurrenceID = occurrenceID {
      completionRecords = completionRecords.filter { $0.occurrence?.id == occurrenceID
      }
    }
    
    // Find completion records from the target date
    let recordsToDelete = completionRecords.filter { record in
      calendar.isDate(record.completedDate, inSameDayAs: targetDay)
    }
    
    var sideEffectResults: [SideEffectExecutionResult]?
    
    // If we have an occurrenceID, only delete the first matching record
    // Otherwise, delete all records from that day (old behavior)
    if occurrenceID != nil && !recordsToDelete.isEmpty {
      // Delete only the most recent completion for this specific occurrence
      if let recordToDelete = recordsToDelete.sorted(by: { $0.completedDate > $1.completedDate }).first {
        sideEffectResults = recordToDelete.decodeSideEffectResults()
        context.delete(recordToDelete)
      }
    } else {
      // Delete all completion records from that day
      sideEffectResults = recordsToDelete.first?.decodeSideEffectResults()
      for record in recordsToDelete {
        context.delete(record)
      }
    }
    
    try context.save()
    return sideEffectResults
  }
  
  // MARK: - Side Effects
  
  func addSideEffect(
    to reminderID: String,
    sideEffect: ReminderSideEffect
  ) throws -> ReminderSideEffectDTO? {
    let descriptor = FetchDescriptor<Reminder>(
      predicate: #Predicate<Reminder> { reminder in
        reminder.id == reminderID
      }
    )
    guard let reminder = try context.fetch(descriptor).first else { return nil }
    
    reminder.addSideEffect(sideEffect)
    context.insert(sideEffect)
    
    try context.save()
    return sideEffect.asDTO()
  }
  
  func updateSideEffect(
    withID id: String,
    configuration: Data
  ) throws -> ReminderSideEffectDTO? {
    let descriptor = FetchDescriptor<ReminderSideEffect>(
      predicate: #Predicate<ReminderSideEffect> { sideEffect in
        sideEffect.id == id
      }
    )
    guard let sideEffect = try context.fetch(descriptor).first else { return nil }
    
    sideEffect.configuration = configuration
    
    try context.save()
    return sideEffect.asDTO()
  }
  
  func deleteSideEffect(withID id: String) throws {
    let descriptor = FetchDescriptor<ReminderSideEffect>(
      predicate: #Predicate<ReminderSideEffect> { sideEffect in
        sideEffect.id == id
      }
    )
    guard let sideEffect = try context.fetch(descriptor).first else { return }
    
    context.delete(sideEffect)
    try context.save()
  }
  
  func updateCompletionRecordWithSideEffectResults(
    completionRecordID: String,
    results: [SideEffectExecutionResult]
  ) throws {
    let descriptor = FetchDescriptor<ReminderCompletionRecord>(
      predicate: #Predicate<ReminderCompletionRecord> { record in
        record.id == completionRecordID
      }
    )
    guard let completionRecord = try context.fetch(descriptor).first else { return }
    
    try completionRecord.encodeSideEffectResults(results)
    try context.save()
  }
}
