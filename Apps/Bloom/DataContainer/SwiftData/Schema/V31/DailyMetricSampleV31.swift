//
//  DailyMetricSampleV31.swift
//  DataContainer
//
//  Created by Claude on 2026-01-09.
//

import Foundation
import SwiftData

extension SchemaV31 {

  /// Stores a single day's aggregated value for a specific health metric.
  /// Used by the Monitor feature to track daily health data and calculate baselines/z-scores.
  @Model
  public final class DailyMetricSample {
    /// Unique identifier in format "{date}_{metricType}" e.g. "2026-01-09_restingHeartRate"
    @Attribute(.unique)
    public var id: String = ""

    /// The date this sample represents (normalized to start of day)
    public var date: Date = Date.distantPast

    /// The type of metric (e.g. "restingHeartRate", "heartRateVariability", "sleepDuration")
    public var metricType: String = ""

    /// The aggregated value for this metric on this date
    public var value: Double = 0

    /// Data quality indicator: "complete", "partial", or "sparse"
    public var quality: String = "complete"

    /// Rolling 7-day baseline average (nil if insufficient data)
    public var baseline7Day: Double?

    /// Rolling 28-day baseline average (nil if insufficient data)
    public var baseline28Day: Double?

    /// Z-score deviation from baseline (nil if baseline unavailable)
    public var zScore: Double?

    public init(
      date: Date,
      metricType: String,
      value: Double,
      quality: String = "complete",
      baseline7Day: Double? = nil,
      baseline28Day: Double? = nil,
      zScore: Double? = nil
    ) {
      self.id = Self.makeID(date: date, metricType: metricType)
      self.date = date
      self.metricType = metricType
      self.value = value
      self.quality = quality
      self.baseline7Day = baseline7Day
      self.baseline28Day = baseline28Day
      self.zScore = zScore
    }

    /// Creates a unique ID from date and metric type
    public static func makeID(date: Date, metricType: String) -> String {
      let formatter = DateFormatter()
      formatter.dateFormat = "yyyy-MM-dd"
      return "\(formatter.string(from: date))_\(metricType)"
    }
  }
}
