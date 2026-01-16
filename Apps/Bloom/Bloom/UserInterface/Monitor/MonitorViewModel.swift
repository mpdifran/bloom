//
//  MonitorViewModel.swift
//  Bloom
//
//  Created by Claude on 2026-01-09.
//

import Foundation
import BloomModel
import UIKit

/// ViewModel for the Monitor tab that manages health monitor states.
@Observable @MainActor
final class MonitorViewModel {

  static let shared = MonitorViewModel()

  /// Current monitor results for all three monitors
  var results: [MonitorResult] = []

  /// Whether data is currently being loaded
  var isLoading = false

  /// Any error that occurred during loading
  var error: Error?

  /// Whether we've completed at least one load
  var hasLoaded = false

  /// Tracks the monitor states that were present when user last viewed the tab.
  /// Used to determine if there are "unseen" alerts that should show a badge.
  private var seenMonitorStates: [MonitorType: MonitorStateValue] = [:]

  private init() { }

  // MARK: - Public Methods

  /// Refresh all monitor states by fetching fresh data from HealthKit
  func refresh() async {
    isLoading = true
    error = nil

    do {
      // Get previous states before calculating (for change detection)
      let previousResults = await DetectionEngine.shared.getAllCachedResults()
      let previousStates: [MonitorType: MonitorStateValue] = Dictionary(
        uniqueKeysWithValues: previousResults.map { ($0.monitorType, $0.state) }
      )

      // Calculate new states
      results = try await MonitorCalculator.shared.calculateMetricsAndDetect()
      hasLoaded = true

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

    isLoading = false
  }

  /// Get cached states without fetching new data
  func loadCached() async {
    let cached = await MonitorCalculator.shared.getCachedStates()
    if !cached.isEmpty {
      results = cached
      hasLoaded = true
      updateBadges()
    }
  }

  /// Updates badge count on tab and app icon based on current results
  func updateBadges() {
    UIApplication.shared.applicationIconBadgeNumber = badgeCount
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
}
