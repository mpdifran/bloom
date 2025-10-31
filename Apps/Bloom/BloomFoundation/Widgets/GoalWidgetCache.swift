//
//  GoalWidgetCache.swift
//  BloomFoundation
//
//  Created by Claude Code on 2025-10-30.
//

import Foundation
import WidgetKit

/// Utility for caching goal data for widgets
public enum GoalWidgetCache {
  /// Cache a single goal's data for widget display
  /// - Parameters:
  ///   - goalData: The goal data to cache
  public static func cacheGoal(_ goalData: GoalWidgetData) {
    guard let encoded = try? JSONEncoder().encode(goalData) else { return }
    UserDefaults.group.set(encoded, forKey: "GoalWidgetCache.\(goalData.id)")
  }

  /// Cache multiple goals at once
  /// - Parameter goals: Array of goal data to cache
  public static func cacheGoals(_ goals: [GoalWidgetData]) {
    // Cache each goal individually
    for goal in goals {
      cacheGoal(goal)
    }

    // Store list of all goal IDs
    let goalIds = goals.map { $0.id }
    if let encoded = try? JSONEncoder().encode(goalIds) {
      UserDefaults.group.set(encoded, forKey: "GoalWidgetCache.AllGoals")
    }

    // Refresh all goal widgets
    refreshWidgets()
  }

  /// Remove a cached goal
  /// - Parameter goalId: The ID of the goal to remove
  public static func removeCachedGoal(_ goalId: String) {
    UserDefaults.group.removeObject(forKey: "GoalWidgetCache.\(goalId)")

    // Update the list of all goal IDs
    if let data = UserDefaults.group.data(forKey: "GoalWidgetCache.AllGoals"),
       var goalIds = try? JSONDecoder().decode([String].self, from: data) {
      goalIds.removeAll { $0 == goalId }
      if let encoded = try? JSONEncoder().encode(goalIds) {
        UserDefaults.group.set(encoded, forKey: "GoalWidgetCache.AllGoals")
      }
    }

    // Refresh widgets
    refreshWidgets()
  }

  /// Clear all cached goal data
  public static func clearCache() {
    // Get all goal IDs
    if let data = UserDefaults.group.data(forKey: "GoalWidgetCache.AllGoals"),
       let goalIds = try? JSONDecoder().decode([String].self, from: data) {
      // Remove each goal's data
      for goalId in goalIds {
        UserDefaults.group.removeObject(forKey: "GoalWidgetCache.\(goalId)")
      }
    }

    // Remove the list of goal IDs
    UserDefaults.group.removeObject(forKey: "GoalWidgetCache.AllGoals")

    // Refresh widgets
    refreshWidgets()
  }

  /// Load a cached goal by ID
  /// - Parameter goalId: The ID of the goal to load
  /// - Returns: The cached goal data, or nil if not found
  public static func loadCachedGoal(_ goalId: String) -> GoalWidgetData? {
    guard let data = UserDefaults.group.data(forKey: "GoalWidgetCache.\(goalId)"),
          let goalData = try? JSONDecoder().decode(GoalWidgetData.self, from: data) else {
      return nil
    }
    return goalData
  }

  /// Load all cached goal IDs
  /// - Returns: Array of goal IDs that are currently cached
  public static func loadAllCachedGoalIds() -> [String] {
    guard let data = UserDefaults.group.data(forKey: "GoalWidgetCache.AllGoals"),
          let goalIds = try? JSONDecoder().decode([String].self, from: data) else {
      return []
    }
    return goalIds
  }

  /// Request a reload of all goal widgets
  public static func refreshWidgets() {
    WidgetCenter.shared.reloadTimelines(ofKind: "GoalWidget")
  }
}
