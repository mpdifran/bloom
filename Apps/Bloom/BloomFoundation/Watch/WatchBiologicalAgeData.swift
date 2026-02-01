//
//  WatchBiologicalAgeData.swift
//  BloomFoundation
//
//  Created by Claude on 2026-01-26.
//

import Foundation

/// Lightweight biological age data for watch synchronization.
/// Contains only the data needed by the watchOS UI.
public struct WatchBiologicalAgeData: Codable, Sendable {
  public let biologicalAge: Double
  public let actualAge: Double
  public let lastCalculated: Date
  public let confidence: WatchBioAgeConfidence?
  public let metricContributions: [WatchMetricContribution]?
  public let chartData: [WatchBioAgeChartPoint]?

  public init(
    biologicalAge: Double,
    actualAge: Double,
    lastCalculated: Date,
    confidence: WatchBioAgeConfidence? = nil,
    metricContributions: [WatchMetricContribution]? = nil,
    chartData: [WatchBioAgeChartPoint]? = nil
  ) {
    self.biologicalAge = biologicalAge
    self.actualAge = actualAge
    self.lastCalculated = lastCalculated
    self.confidence = confidence
    self.metricContributions = metricContributions
    self.chartData = chartData
  }
}

// MARK: - WatchBioAgeConfidence

/// Confidence level for biological age calculation
public enum WatchBioAgeConfidence: String, Codable, Sendable {
  case high
  case moderate
  case low

  public var displayName: String {
    switch self {
    case .high: "High"
    case .moderate: "Moderate"
    case .low: "Low"
    }
  }
}

// MARK: - WatchMetricContribution

/// Simplified metric contribution for watch display
public struct WatchMetricContribution: Codable, Sendable, Identifiable {
  public var id: String { metric }
  public let metric: String
  public let category: String
  public let weightedDelta: Double

  public init(metric: String, category: String, weightedDelta: Double) {
    self.metric = metric
    self.category = category
    self.weightedDelta = weightedDelta
  }

  /// True if this metric is making the user younger (negative delta)
  public var isPositive: Bool {
    weightedDelta < -0.1
  }

  /// True if this metric is making the user older (positive delta)
  public var isNegative: Bool {
    weightedDelta > 0.1
  }

  /// True if this metric has minimal effect
  public var isNeutral: Bool {
    abs(weightedDelta) <= 0.1
  }
}

// MARK: - WatchBioAgeChartPoint

/// Data point for biological age trend chart
public struct WatchBioAgeChartPoint: Codable, Sendable, Identifiable {
  public var id: Date { date }
  public let date: Date
  public let biologicalAge: Double

  public init(date: Date, biologicalAge: Double) {
    self.date = date
    self.biologicalAge = biologicalAge
  }
}
