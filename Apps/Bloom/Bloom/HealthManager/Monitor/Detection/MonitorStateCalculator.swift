//
//  MonitorStateCalculator.swift
//  Bloom
//
//  Created by Claude on 2026-01-09.
//

import Foundation
import DataContainer

/// Protocol for individual monitor state calculators.
/// Each calculator is responsible for analyzing metric samples and producing a state for its monitor type.
public protocol MonitorStateCalculator: Sendable {

  /// The type of monitor this calculator handles
  var monitorType: MonitorType { get }

  /// The metrics required for this monitor to function
  var requiredMetrics: [MonitorMetricType] { get }

  /// The optional metrics that enhance accuracy
  var optionalMetrics: [MonitorMetricType] { get }

  /// Calculate the state for a given date using historical samples
  /// - Parameters:
  ///   - date: The date to calculate state for
  ///   - samples: Historical DailyMetricSample data for relevant metrics
  ///   - previousResults: Previous MonitorResults for persistence checking
  /// - Returns: A MonitorResult with state, confidence, and findings
  func calculateState(
    for date: Date,
    samples: [DailyMetricSampleDTO],
    previousResults: [MonitorResult]
  ) async -> MonitorResult
}

// MARK: - Shared Utilities

/// Counts consecutive days in the same (or worse) state going backwards from currentDate.
/// Used to implement the 2-day persistence rule.
func countConsecutiveDays(
  state: MonitorStateValue,
  previousResults: [MonitorResult],
  currentDate: Date
) -> Int {
  let calendar = Calendar.current

  // Sort previous results by date descending
  let sorted = previousResults.sorted { $0.calculatedAt > $1.calculatedAt }

  var count = 1 // Today counts as day 1
  var expectedDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!

  for result in sorted {
    // Check if this result is for the expected previous day
    guard calendar.isDate(result.calculatedAt, inSameDayAs: expectedDate) else {
      break
    }

    // Check if state matches (or is "worse" - Alert matches Attention for continuity)
    let matches: Bool
    switch state {
    case .alert:
      // Alert continues if previous was Alert or Attention
      matches = result.state == .alert || result.state == .attention
    case .attention:
      // Attention continues if previous was Attention or Alert
      matches = result.state == .attention || result.state == .alert
    case .good:
      matches = result.state == .good
    case .unavailable:
      matches = result.state == .unavailable
    case .encourage:
      matches = result.state == .encourage
    }

    if matches {
      count += 1
      expectedDate = calendar.date(byAdding: .day, value: -1, to: expectedDate)!
    } else {
      break
    }
  }

  return count
}

/// Calculates confidence based on available optional data.
/// - Parameters:
///   - requiredPresent: Whether all required metrics are present
///   - optionalMetrics: List of optional metrics for the monitor
///   - presentMetrics: Set of metric types that have data
/// - Returns: Confidence value between 0.0 and 1.0
func calculateConfidence(
  requiredPresent: Bool,
  optionalMetrics: [MonitorMetricType],
  presentMetrics: Set<String>
) -> Double {
  guard requiredPresent else { return 0 }

  // Base confidence from required metrics only
  var confidence = 0.6

  // Each optional metric adds to confidence
  let optionalBonus = optionalMetrics.isEmpty ? 0 : 0.4 / Double(optionalMetrics.count)
  for metric in optionalMetrics {
    if presentMetrics.contains(metric.rawValue) {
      confidence += optionalBonus
    }
  }

  return min(confidence, 1.0)
}
