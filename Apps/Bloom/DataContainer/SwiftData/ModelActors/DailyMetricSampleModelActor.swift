//
//  DailyMetricSampleModelActor.swift
//  DataContainer
//
//  Created by Claude on 2026-01-09.
//

import Foundation
import SwiftData
import BloomFoundation

@ModelActor
public final actor DailyMetricSampleModelActor: Sendable, SharedModelActor {

  private var context: ModelContext { modelExecutor.modelContext }
}

public extension DailyMetricSampleModelActor {

  /// Fetch a specific sample by date and metric type
  func fetch(date: Date, metricType: String) throws -> DailyMetricSampleDTO? {
    let id = DailyMetricSample.makeID(date: date, metricType: metricType)
    let descriptor = FetchDescriptor<DailyMetricSample>(
      predicate: #Predicate<DailyMetricSample> { sample in
        sample.id == id
      }
    )
    return try context.fetch(descriptor).first?.asDTO()
  }

  /// Fetch all samples for a specific metric type within a date range
  func fetchSamples(metricType: String, dateRange: DateRange) throws -> [DailyMetricSampleDTO] {
    let start = dateRange.start
    let end = dateRange.end
    let descriptor = FetchDescriptor<DailyMetricSample>(
      predicate: #Predicate<DailyMetricSample> { sample in
        sample.metricType == metricType && sample.date >= start && sample.date <= end
      },
      sortBy: [SortDescriptor(\DailyMetricSample.date)]
    )
    return try context.fetch(descriptor).map { $0.asDTO() }
  }

  /// Fetch samples for multiple metric types within a date range
  func fetchSamples(metricTypes: [String], dateRange: DateRange) throws -> [DailyMetricSampleDTO] {
    let start = dateRange.start
    let end = dateRange.end
    let descriptor = FetchDescriptor<DailyMetricSample>(
      predicate: #Predicate<DailyMetricSample> { sample in
        sample.date >= start && sample.date <= end
      },
      sortBy: [SortDescriptor(\DailyMetricSample.date)]
    )
    return try context.fetch(descriptor)
      .filter { metricTypes.contains($0.metricType) }
      .map { $0.asDTO() }
  }

  /// Fetch the latest sample for a specific metric type
  func fetchLatest(metricType: String) throws -> DailyMetricSampleDTO? {
    var descriptor = FetchDescriptor<DailyMetricSample>(
      predicate: #Predicate<DailyMetricSample> { sample in
        sample.metricType == metricType
      },
      sortBy: [SortDescriptor(\DailyMetricSample.date, order: .reverse)]
    )
    descriptor.fetchLimit = 1
    return try context.fetch(descriptor).first?.asDTO()
  }

  /// Upsert a daily metric sample - updates existing or inserts new
  func upsert(
    date: Date,
    metricType: String,
    value: Double,
    quality: String = "complete",
    baseline7Day: Double? = nil,
    baseline28Day: Double? = nil,
    zScore: Double? = nil
  ) throws {
    let id = DailyMetricSample.makeID(date: date, metricType: metricType)
    let descriptor = FetchDescriptor<DailyMetricSample>(
      predicate: #Predicate<DailyMetricSample> { sample in
        sample.id == id
      }
    )

    if let existingSample = try context.fetch(descriptor).first {
      existingSample.value = value
      existingSample.quality = quality
      existingSample.baseline7Day = baseline7Day
      existingSample.baseline28Day = baseline28Day
      existingSample.zScore = zScore
    } else {
      let sample = DailyMetricSample(
        date: date,
        metricType: metricType,
        value: value,
        quality: quality,
        baseline7Day: baseline7Day,
        baseline28Day: baseline28Day,
        zScore: zScore
      )
      context.insert(sample)
    }
    try context.save()
  }

  /// Batch upsert multiple samples from input data
  func upsertBatch(_ inputs: [DailyMetricSampleInput]) throws {
    for input in inputs {
      let inputId = input.id
      let descriptor = FetchDescriptor<DailyMetricSample>(
        predicate: #Predicate<DailyMetricSample> { s in
          s.id == inputId
        }
      )

      if let existingSample = try context.fetch(descriptor).first {
        existingSample.value = input.value
        existingSample.quality = input.quality
        existingSample.baseline7Day = input.baseline7Day
        existingSample.baseline28Day = input.baseline28Day
        existingSample.zScore = input.zScore
      } else {
        let newSample = DailyMetricSample(
          date: input.date,
          metricType: input.metricType,
          value: input.value,
          quality: input.quality,
          baseline7Day: input.baseline7Day,
          baseline28Day: input.baseline28Day,
          zScore: input.zScore
        )
        context.insert(newSample)
      }
    }
    try context.save()
  }

  /// Delete samples older than a specified date (for retention cleanup)
  func deleteOldSamples(olderThan date: Date) throws {
    let descriptor = FetchDescriptor<DailyMetricSample>(
      predicate: #Predicate<DailyMetricSample> { sample in
        sample.date < date
      }
    )
    let oldSamples = try context.fetch(descriptor)
    for sample in oldSamples {
      context.delete(sample)
    }
    try context.save()
  }

  /// Delete all samples (for testing/reset)
  func deleteAll() throws {
    let descriptor = FetchDescriptor<DailyMetricSample>()
    let allSamples = try context.fetch(descriptor)
    for sample in allSamples {
      context.delete(sample)
    }
    try context.save()
  }
}
