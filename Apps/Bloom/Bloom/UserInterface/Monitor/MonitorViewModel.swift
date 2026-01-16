//
//  MonitorViewModel.swift
//  Bloom
//
//  Created by Claude on 2026-01-09.
//

import Foundation
import BloomModel

/// ViewModel for the Monitor tab that manages health monitor states.
@Observable @MainActor
final class MonitorViewModel {

  static let shared = MonitorViewModel()

  /// Current monitor results for all three monitors
  var results: [MonitorResult] = []

  /// Cached AI-generated summary (when monitors need attention)
  var aiSummary: MonitorSummaryResponse?

  /// Whether data is currently being loaded
  var isLoading = false

  /// Any error that occurred during loading
  var error: Error?

  /// Whether we've completed at least one load
  var hasLoaded = false

  private init() { }

  // MARK: - Public Methods

  /// Refresh all monitor states by fetching fresh data from HealthKit
  func refresh() async {
    isLoading = true
    error = nil

    do {
      results = try await MonitorCalculator.shared.calculateMetricsAndDetect()
      hasLoaded = true
    } catch {
      self.error = error
    }

    isLoading = false
  }

  /// Get cached states without fetching new data
  func loadCached() async {
    let cached = await MonitorCalculator.shared.getCachedStates()
    if !cached.isEmpty {
      results = cached
      hasLoaded = true
    }

    // Load cached AI summary
    aiSummary = await MonitorSummaryCache.shared.getCachedSummary()
  }

  // MARK: - Computed Properties

  /// Whether all monitors are in "Good" state
  var isAllGood: Bool {
    guard !results.isEmpty else { return false }
    return results.allSatisfy { $0.state == .good }
  }

  /// Monitors that need attention (Watch or Off state)
  var monitorsNeedingAttention: [MonitorResult] {
    results.filter { $0.state.isConcerning }
  }

  /// Monitors with encouragement state (positive nudge to exercise)
  var monitorsWithEncouragement: [MonitorResult] {
    results.filter { $0.state == .encourage }
  }

  /// Get result for a specific monitor type
  func result(for monitorType: MonitorType) -> MonitorResult? {
    results.first { $0.monitorType == monitorType }
  }
}
