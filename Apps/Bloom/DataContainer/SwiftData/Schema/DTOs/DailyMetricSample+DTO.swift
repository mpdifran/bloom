//
//  DailyMetricSample+DTO.swift
//  DataContainer
//
//  Created by Claude on 2026-01-09.
//

import Foundation
import SwiftData

/// DTO for reading DailyMetricSample data from SwiftData
public struct DailyMetricSampleDTO: Sendable, Identifiable, Equatable {
  public let id: String
  public let persistentModelID: PersistentIdentifier
  public let date: Date
  public let metricType: String
  public let value: Double
  public let quality: String
  public let baseline7Day: Double?
  public let baseline28Day: Double?
  public let zScore: Double?
}

public extension DailyMetricSample {

  func asDTO() -> DailyMetricSampleDTO {
    DailyMetricSampleDTO(
      id: id,
      persistentModelID: persistentModelID,
      date: date,
      metricType: metricType,
      value: value,
      quality: quality,
      baseline7Day: baseline7Day,
      baseline28Day: baseline28Day,
      zScore: zScore
    )
  }
}

/// Data structure for displaying metric ranges in the UI.
/// Contains the current value, 7-day range, and baseline for chart visualization.
public struct MetricRangeData: Sendable, Equatable, Identifiable {
  public var id: String { metricType }
  public let metricType: String
  public let displayName: String
  public let currentValue: Double
  public let min7Day: Double
  public let max7Day: Double
  public let baseline28Day: Double?
  public let zScore: Double?

  public init(
    metricType: String,
    displayName: String,
    currentValue: Double,
    min7Day: Double,
    max7Day: Double,
    baseline28Day: Double?,
    zScore: Double?
  ) {
    self.metricType = metricType
    self.displayName = displayName
    self.currentValue = currentValue
    self.min7Day = min7Day
    self.max7Day = max7Day
    self.baseline28Day = baseline28Day
    self.zScore = zScore
  }

  /// The range span (max - min)
  public var rangeSpan: Double {
    max7Day - min7Day
  }

  /// Position of current value as 0-1 within the 7-day range
  public var normalizedPosition: Double {
    guard rangeSpan > 0 else { return 0.5 }
    return (currentValue - min7Day) / rangeSpan
  }

  /// Position of baseline as 0-1 within the 7-day range
  public var normalizedBaselinePosition: Double? {
    guard let baseline = baseline28Day, rangeSpan > 0 else { return nil }
    return (baseline - min7Day) / rangeSpan
  }
}

/// Input struct for creating/updating DailyMetricSample records.
/// Used when persisting new data before it has a PersistentIdentifier.
public struct DailyMetricSampleInput: Sendable, Equatable {
  public let date: Date
  public let metricType: String
  public let value: Double
  public let quality: String
  public let baseline7Day: Double?
  public let baseline28Day: Double?
  public let zScore: Double?

  public init(
    date: Date,
    metricType: String,
    value: Double,
    quality: String = "complete",
    baseline7Day: Double? = nil,
    baseline28Day: Double? = nil,
    zScore: Double? = nil
  ) {
    self.date = date
    self.metricType = metricType
    self.value = value
    self.quality = quality
    self.baseline7Day = baseline7Day
    self.baseline28Day = baseline28Day
    self.zScore = zScore
  }

  /// The computed ID for this sample
  public var id: String {
    DailyMetricSample.makeID(date: date, metricType: metricType)
  }
}
