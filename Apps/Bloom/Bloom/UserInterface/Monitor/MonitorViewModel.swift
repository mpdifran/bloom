//
//  MonitorViewModel.swift
//  Bloom
//
//  Created by Claude on 2026-01-09.
//

import Foundation
import BloomModel
import UIKit
import UserNotifications

/// ViewModel for the Monitor tab that manages health monitor states.
@Observable @MainActor
final class MonitorViewModel {

  static let shared = MonitorViewModel()

  /// Current monitor results for all three monitors
  var results: [MonitorResult] = []

  /// Any error that occurred during loading
  var error: Error?

  /// Whether we've completed at least one load
  var hasLoaded = false

  /// Timestamp of the last successful refresh
  private(set) var lastRefreshDate: Date?

  /// Staleness threshold: 5 minutes
  private let stalenessInterval: TimeInterval = 5 * 60

  /// Tracks the monitor states that were present when user last viewed the tab.
  /// Used to determine if there are "unseen" alerts that should show a badge.
  private var seenMonitorStates: [MonitorType: MonitorStateValue] = [:]

  private init() { }

  // MARK: - Staleness

  /// Whether data is stale and needs refreshing
  var isStale: Bool {
    guard let lastRefresh = lastRefreshDate else { return true }
    return Date().timeIntervalSince(lastRefresh) > stalenessInterval
  }

  // MARK: - Public Methods

  /// Refreshes data only if stale or never loaded.
  func refreshIfNeeded() async {
    guard isStale else { return }
    await refresh()
  }

  /// Refresh all monitor states by fetching fresh data from HealthKit
  func refresh() async {
    error = nil

    do {
      // Get previous states before calculating (for change detection)
      let previousResults = await DetectionEngine.shared.getAllCachedResults()
      let previousStates: [MonitorType: MonitorStateValue] = Dictionary(
        uniqueKeysWithValues: previousResults.map { ($0.monitorType, $0.state) }
      )

      // Calculate new states
      let calculatedResults = try await MonitorCalculator.shared.calculateMetricsAndDetect()
      results = ensureAllMonitorTypes(calculatedResults)
      hasLoaded = true
      lastRefreshDate = Date()

      // Check for state changes and send notifications
      for result in results {
        let previousState = previousStates[result.monitorType]
        await MonitorNotificationScheduler.shared.scheduleNotificationIfNeeded(
          result: result,
          previousState: previousState
        )
      }

      // Update badges
      updateBadges()
    } catch {
      self.error = error
    }
  }

  /// Get cached states without fetching new data
  func loadCached() async {
    let cached = await MonitorCalculator.shared.getCachedStates()
    results = ensureAllMonitorTypes(cached)
    if !cached.isEmpty {
      hasLoaded = true
      updateBadges()
    }
  }

  /// Updates badge count on tab and app icon based on current results
  func updateBadges() {
    UNUserNotificationCenter.current().setBadgeCount(badgeCount)
  }

  /// Call when user views the Monitor tab to mark current alerts as "seen"
  func markAlertsAsSeen() {
    for result in results {
      seenMonitorStates[result.monitorType] = result.state
    }
    updateBadges()
  }

  // MARK: - Computed Properties

  /// Badge count for tab and app icon - only counts unseen concerning states
  var badgeCount: Int {
    guard MonitorNotificationPreferences.shared.badgesEnabled else { return 0 }
    return results.filter { result in
      guard result.state.isConcerning else { return false }
      // Only count if user hasn't seen this exact state
      return seenMonitorStates[result.monitorType] != result.state
    }.count
  }

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

  // MARK: - Private Helpers

  /// Ensures all monitor types have a result, filling in unavailable placeholders.
  private func ensureAllMonitorTypes(_ results: [MonitorResult]) -> [MonitorResult] {
    var resultsByType = Dictionary(uniqueKeysWithValues: results.map { ($0.monitorType, $0) })

    for monitorType in MonitorType.allCases {
      if resultsByType[monitorType] == nil {
        resultsByType[monitorType] = MonitorResult(
          monitorType: monitorType,
          state: .unavailable,
          confidence: 0,
          consecutiveDays: 0,
          signals: [],
          findings: []
        )
      }
    }

    return MonitorType.allCases.compactMap { resultsByType[$0] }
  }
}
