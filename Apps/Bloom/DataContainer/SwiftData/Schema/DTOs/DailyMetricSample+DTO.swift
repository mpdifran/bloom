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
  public let currentValue: Double?
  public let min7Day: Double?
  public let max7Day: Double?
  public let baseline28Day: Double?
  public let zScore: Double?
  public let min7DayZScore: Double?
  public let max7DayZScore: Double?

  /// Whether this metric has actual data (vs placeholder)
  public var hasData: Bool { currentValue != nil }

  public init(
    metricType: String,
    displayName: String,
    currentValue: Double?,
    min7Day: Double?,
    max7Day: Double?,
    baseline28Day: Double?,
    zScore: Double?,
    min7DayZScore: Double? = nil,
    max7DayZScore: Double? = nil
  ) {
    self.metricType = metricType
    self.displayName = displayName
    self.currentValue = currentValue
    self.min7Day = min7Day
    self.max7Day = max7Day
    self.baseline28Day = baseline28Day
    self.zScore = zScore
    self.min7DayZScore = min7DayZScore
    self.max7DayZScore = max7DayZScore
  }

  /// The range span (max - min)
  public var rangeSpan: Double? {
    guard let min = min7Day, let max = max7Day else { return nil }
    return max - min
  }

  /// Position of current value as 0-1 within the 7-day range
  public var normalizedPosition: Double? {
    guard let span = rangeSpan, span > 0,
          let current = currentValue, let min = min7Day else { return nil }
    return (current - min) / span
  }

  /// Position of baseline as 0-1 within the 7-day range
  public var normalizedBaselinePosition: Double? {
    guard let baseline = baseline28Day,
          let span = rangeSpan, span > 0,
          let min = min7Day else { return nil }
    return (baseline - min) / span
  }
}

/// Data for MonitorSummaryBar - aggregates z-scores across all metrics for a monitor.
/// Shows the 7-day z-score range and current z-score positions for each metric.
public struct MonitorSummaryBarData: Sendable, Equatable {
  /// Today's z-scores per metric
  public let metricZScores: [MetricZScorePoint]
  /// 7-day minimum z-score across all metrics
  public let min7DayZScore: Double
  /// 7-day maximum z-score across all metrics
  public let max7DayZScore: Double

  public init(
    metricZScores: [MetricZScorePoint],
    min7DayZScore: Double,
    max7DayZScore: Double
  ) {
    self.metricZScores = metricZScores
    self.min7DayZScore = min7DayZScore
    self.max7DayZScore = max7DayZScore
  }
}

/// A single metric's current z-score for dot placement on the summary bar.
public struct MetricZScorePoint: Sendable, Equatable, Identifiable {
  public var id: String { metricType }
  public let metricType: String
  public let zScore: Double

  public init(metricType: String, zScore: Double) {
    self.metricType = metricType
    self.zScore = zScore
  }
}

/// Z-score range for a single day, used by MonitorStateChart.
public struct DayZScoreRange: Sendable, Equatable, Identifiable {
  public var id: Date { date }
  public let date: Date
  public let minZScore: Double
  public let maxZScore: Double

  public init(date: Date, minZScore: Double, maxZScore: Double) {
    self.date = date
    self.minZScore = minZScore
    self.maxZScore = maxZScore
  }
}

public extension MonitorSummaryBarData {
  /// Empty placeholder data - centered bar with no dots
  static let empty = MonitorSummaryBarData(
    metricZScores: [],
    min7DayZScore: 0,
    max7DayZScore: 0
  )

  /// Creates summary bar data from a single metric's range data.
  /// Returns nil if z-score data is not available.
  init?(from rangeData: MetricRangeData) {
    guard let zScore = rangeData.zScore,
          let minZ = rangeData.min7DayZScore,
          let maxZ = rangeData.max7DayZScore else { return nil }

    self.init(
      metricZScores: [MetricZScorePoint(metricType: rangeData.metricType, zScore: zScore)],
      min7DayZScore: minZ,
      max7DayZScore: maxZ
    )
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
