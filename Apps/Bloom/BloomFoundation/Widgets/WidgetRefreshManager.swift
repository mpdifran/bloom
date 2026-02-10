//
//  WidgetRefreshManager.swift
//  BloomFoundation
//
//  Created by Claude Code on 2025-10-19.
//

import Foundation
import WidgetKit

/// Centralized manager for refreshing widget timelines throughout the app
public final class WidgetRefreshManager {
  public static let shared = WidgetRefreshManager()

  private init() {}

  /// Reload a specific widget's timeline
  /// - Parameter kind: The widget kind identifier
  public func reloadWidget(kind: String) {
    WidgetCenter.shared.reloadTimelines(ofKind: kind)
  }

  /// Reload all widget timelines
  public func reloadAllWidgets() {
    WidgetCenter.shared.reloadAllTimelines()
  }

  /// Reload Today-related widgets (Today Insight widget)
  public func reloadTodayWidgets() {
    WidgetCenter.shared.reloadTimelines(ofKind: .WidgetKind.todayInsight)
  }

  /// Reload Health Insight widgets
  public func reloadHealthInsightWidgets() {
    WidgetCenter.shared.reloadTimelines(ofKind: .WidgetKind.healthInsight)
  }

  /// Reload Bud Summary widgets
  public func reloadBudSummaryWidgets() {
    WidgetCenter.shared.reloadTimelines(ofKind: .WidgetKind.budSummary)
  }

  /// Reload Nutrition-related widgets (Log Meal widget)
  public func reloadNutritionWidgets() {
    WidgetCenter.shared.reloadTimelines(ofKind: .WidgetKind.logMeal)
  }

  /// Reload Action Control widgets
  public func reloadActionControlWidgets() {
    WidgetCenter.shared.reloadTimelines(ofKind: .WidgetKind.actionControl)
  }

  /// Reload Steps widgets
  public func reloadStepsWidgets() {
    WidgetCenter.shared.reloadTimelines(ofKind: .WidgetKind.steps)
  }

  #if os(watchOS)
  /// Reload Biological Age widget on watchOS
  public func reloadBiologicalAgeWidget() {
    WidgetCenter.shared.reloadTimelines(ofKind: "BiologicalAgeWidget")
  }

  /// Reload Watch Goal widget on watchOS
  public func reloadWatchGoalWidget() {
    WidgetCenter.shared.reloadTimelines(ofKind: "WatchGoalWidget")
  }
  #endif
}
