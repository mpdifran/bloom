//
//  BiologicalAgeRecordModelActor.swift
//  DataContainer
//
//  Created by Mark DiFranco on 2026-01-03.
//

import Foundation
import SwiftData
import BloomFoundation

@ModelActor
public final actor BiologicalAgeRecordModelActor: Sendable, SharedModelActor {

  private var context: ModelContext { modelExecutor.modelContext }
}

public extension BiologicalAgeRecordModelActor {

  /// Fetch the most recent biological age record
  func fetchLatest() throws -> BiologicalAgeRecordDTO? {
    var descriptor = FetchDescriptor<BiologicalAgeRecord>(
      sortBy: [SortDescriptor(\BiologicalAgeRecord.date, order: .reverse)]
    )
    descriptor.fetchLimit = 1

    return try context.fetch(descriptor).first?.asDTO()
  }

  /// Fetch all biological age records within a date range (for charting)
  func fetchRecords(dateRange: DateRange) throws -> [BiologicalAgeRecordDTO] {
    let start = dateRange.start
    let end = dateRange.end
    let descriptor = FetchDescriptor<BiologicalAgeRecord>(
      predicate: #Predicate<BiologicalAgeRecord> { record in
        record.date >= start && record.date <= end
      },
      sortBy: [SortDescriptor(\BiologicalAgeRecord.date)]
    )

    return try context.fetch(descriptor).map { $0.asDTO() }
  }

  /// Fetch all biological age records (for charting full history)
  func fetchAllRecords() throws -> [BiologicalAgeRecordDTO] {
    let descriptor = FetchDescriptor<BiologicalAgeRecord>(
      sortBy: [SortDescriptor(\BiologicalAgeRecord.date)]
    )

    return try context.fetch(descriptor).map { $0.asDTO() }
  }

  /// Save a new biological age record
  func save(biologicalAge: Double, actualAge: Double, date: Date = .now) throws {
    let record = BiologicalAgeRecord(
      date: date,
      biologicalAge: biologicalAge,
      actualAge: actualAge
    )
    context.insert(record)
    try context.save()
  }

  /// Upsert a biological age record - updates existing same-day record or inserts new one
  func upsert(biologicalAge: Double, actualAge: Double, date: Date = .now) throws {
    let startOfDay = Calendar.current.startOfDay(for: date)
    let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

    let descriptor = FetchDescriptor<BiologicalAgeRecord>(
      predicate: #Predicate<BiologicalAgeRecord> { record in
        record.date >= startOfDay && record.date < endOfDay
      }
    )

    if let existingRecord = try context.fetch(descriptor).first {
      // Update existing record for today
      existingRecord.biologicalAge = biologicalAge
      existingRecord.actualAge = actualAge
      existingRecord.date = date
    } else {
      // Insert new record
      let record = BiologicalAgeRecord(
        date: date,
        biologicalAge: biologicalAge,
        actualAge: actualAge
      )
      context.insert(record)
    }
    try context.save()
  }

  /// Fetch the previous calendar day's record for blending
  func fetchPreviousDayRecord() throws -> BiologicalAgeRecordDTO? {
    let today = Calendar.current.startOfDay(for: Date())
    guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) else {
      return nil
    }
    let endOfYesterday = today

    let descriptor = FetchDescriptor<BiologicalAgeRecord>(
      predicate: #Predicate<BiologicalAgeRecord> { record in
        record.date >= yesterday && record.date < endOfYesterday
      },
      sortBy: [SortDescriptor(\BiologicalAgeRecord.date, order: .reverse)]
    )

    return try context.fetch(descriptor).first?.asDTO()
  }
}
