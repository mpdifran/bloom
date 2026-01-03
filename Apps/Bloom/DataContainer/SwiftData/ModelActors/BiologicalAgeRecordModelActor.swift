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
}
