//
//  DetectionEngine.swift
//  Bloom
//
//  Created by Claude on 2026-01-09.
//

import Foundation
import DataContainer
import BloomFoundation

/// Main orchestrator for the Monitor Detection Engine.
/// Coordinates the three monitor calculators and provides a unified interface for calculating states.
public actor DetectionEngine {

  public static let shared = DetectionEngine()

  private let recoveryCalculator = RecoveryStateCalculator()
  private let stressCalculator = StressStateCalculator()
  private let sleepCalculator = SleepStateCalculator()

  /// Previous results cache for persistence checking (last 7 days)
  private var previousResults: [MonitorType: [MonitorResult]] = [
    .recovery: [],
    .stress: [],
    .sleep: []
  ]

  private init() { }

  // MARK: - Public API

  /// Calculate all monitor states for a given date.
  /// - Parameter date: The date to calculate states for (defaults to today)
  /// - Returns: Array of MonitorResult for each monitor type
  public func calculateAllStates(for date: Date = Date()) async throws -> [MonitorResult] {
    let modelActor = DailyMetricSampleModelActor.standard()
    let calendar = Calendar.current

    // Standard 30-day fetch for recovery and sleep monitors
    guard let startDate30 = calendar.date(byAdding: .day, value: -30, to: date) else {
      return []
    }

    // Extended 180-day fetch for stress monitor (to support encourage state classification)
    guard let startDate180 = calendar.date(byAdding: .day, value: -180, to: date) else {
      return []
    }

    let dateRange30 = DateRange(startDate30, date)
    let dateRange180 = DateRange(startDate180, date)
    let allMetricTypes = MonitorMetricType.allCases.map { $0.rawValue }

    // Fetch standard samples for recovery and sleep
    let samples30 = try await modelActor.fetchSamples(
      metricTypes: allMetricTypes,
      dateRange: dateRange30
    )

    // Fetch extended active energy samples for stress calculator
    let extendedEnergySamples = try await modelActor.fetchSamples(
      metricTypes: [MonitorMetricType.activeEnergy.rawValue],
      dateRange: dateRange180
    )

    // Merge for stress: all 30-day samples except active energy, plus all 180-day active energy
    let stressSamples = samples30.filter {
      $0.metricType != MonitorMetricType.activeEnergy.rawValue
    } + extendedEnergySamples

    // Calculate each monitor state in parallel
    async let recoveryResult = recoveryCalculator.calculateState(
      for: date,
      samples: samples30,
      previousResults: previousResults[.recovery] ?? []
    )

    async let stressResult = stressCalculator.calculateState(
      for: date,
      samples: stressSamples,
      previousResults: previousResults[.stress] ?? []
    )

    async let sleepResult = sleepCalculator.calculateState(
      for: date,
      samples: samples30,
      previousResults: previousResults[.sleep] ?? []
    )

    let results = await [recoveryResult, stressResult, sleepResult]

    // Update previous results cache (keep last 7 days)
    for result in results {
      var history = previousResults[result.monitorType] ?? []
      history.insert(result, at: 0)
      if history.count > 7 {
        history = Array(history.prefix(7))
      }
      previousResults[result.monitorType] = history
    }

    return results
  }

  /// Calculate state for a specific monitor.
  /// - Parameters:
  ///   - monitorType: The monitor type to calculate
  ///   - date: The date to calculate for (defaults to today)
  /// - Returns: MonitorResult for the specified monitor
  public func calculateState(for monitorType: MonitorType, date: Date = Date()) async throws -> MonitorResult {
    let allResults = try await calculateAllStates(for: date)
    return allResults.first { $0.monitorType == monitorType } ?? .unavailable(
      monitorType: monitorType,
      reason: "Unable to calculate state.",
      requiredMetrics: []
    )
  }

  /// Get the most recent result for a monitor type without recalculating.
  /// Returns nil if no previous result exists.
  public func getCachedResult(for monitorType: MonitorType) -> MonitorResult? {
    previousResults[monitorType]?.first
  }

  /// Get all cached results without recalculating.
  public func getAllCachedResults() -> [MonitorResult] {
    MonitorType.allCases.compactMap { getCachedResult(for: $0) }
  }

  /// Clear the results cache (useful for testing or reset).
  public func clearCache() {
    previousResults = [
      .recovery: [],
      .stress: [],
      .sleep: []
    ]
  }

  /// Load historical results from persistence (call on app launch).
  /// This populates the cache with previous days' results for persistence rule checking.
  public func loadHistoricalResults(days: Int = 7) async throws {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())

    // Clear existing cache
    clearCache()

    // Calculate for each day going backwards (oldest first so cache builds correctly)
    for dayOffset in (1...days).reversed() {
      guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
      _ = try await calculateAllStates(for: date)
    }
  }
}

// MARK: - Summary Helpers

public extension DetectionEngine {

  /// Returns the overall status across all monitors.
  /// - Returns: The most severe state among all monitors
  func overallStatus() async throws -> MonitorStateValue {
    let results = try await calculateAllStates()
    let states = results.map { $0.state }

    // Return most severe state first, then encourage, then good
    if states.contains(.alert) { return .alert }
    if states.contains(.attention) { return .attention }
    if states.contains(.encourage) { return .encourage }
    if states.allSatisfy({ $0 == .unavailable }) { return .unavailable }
    return .good
  }

  /// Returns monitors that need attention (Watch or Off state).
  func monitorsNeedingAttention() async throws -> [MonitorResult] {
    let results = try await calculateAllStates()
    return results.filter { $0.state.isConcerning }
  }

  /// Returns true if all monitors are in Good state.
  func isAllGood() async throws -> Bool {
    let results = try await calculateAllStates()
    return results.allSatisfy { $0.state == .good }
  }

  /// Calculate historical states for a specific monitor over a date range.
  /// - Parameters:
  ///   - monitorType: The monitor type to calculate history for
  ///   - days: Number of days to look back (including today)
  /// - Returns: Array of MonitorResult sorted by date (oldest first)
  func calculateHistoricalStates(for monitorType: MonitorType, days: Int) async throws -> [MonitorResult] {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())

    var results: [MonitorResult] = []

    // Calculate for each day (oldest to newest)
    for dayOffset in (0..<days).reversed() {
      guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
      let result = try await calculateState(for: monitorType, date: date)
      results.append(result)
    }

    return results
  }
}
