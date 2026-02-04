//
//  WatchGoalSyncer.swift
//  Bloom
//
//  Created by Claude on 2026-02-01.
//

import Foundation
import BloomFoundation

/// Syncs goal data to the Apple Watch
@MainActor
final class WatchGoalSyncer {
  static let shared = WatchGoalSyncer()

  private init() {}

  /// Syncs goals to watch using both application context and complication API.
  /// The complication API provides priority delivery to update widgets immediately.
  func syncToWatch() async {
    #if os(iOS)
    // Load goals from the widget cache
    let cachedGoals = GoalWidgetCache.loadAllCachedGoals()

    // Convert to watch-friendly format
    let watchGoals = cachedGoals.compactMap { goalData -> WatchGoal? in
      guard let metricName = goalData.metricName else { return nil }

      return WatchGoal(
        id: goalData.id,
        metricName: metricName,
        metricSystemImage: goalData.metricSystemImage ?? "target",
        metricColorHex: goalData.metricColorHex,
        targetValue: goalData.targetValue,
        targetUnit: goalData.targetUnit,
        timePeriod: goalData.timePeriod
      )
    }

    let watchData = WatchGoalData(
      goals: watchGoals,
      lastUpdated: Date()
    )

    guard let data = try? JSONEncoder.watch.encode(watchData) else {
      print("Failed to encode watch goal data")
      return
    }

    // Use complication transfer for immediate widget update
    let remainingTransfers = await WatchChannel.shared.transferComplicationUserInfo(
      key: WatchChannel.goalsDataKey,
      data: data
    )

    if remainingTransfers < 10 {
      print("Warning: Only \(remainingTransfers) complication transfers remaining today")
    }

    // Also update application context as a fallback for watch app
    do {
      try await WatchChannel.shared.updateApplicationContext(
        key: WatchChannel.goalsDataKey,
        data: data
      )
    } catch {
      print("Failed to sync goals to watch via application context: \(error)")
    }
    #endif
  }
}
