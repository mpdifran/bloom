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
