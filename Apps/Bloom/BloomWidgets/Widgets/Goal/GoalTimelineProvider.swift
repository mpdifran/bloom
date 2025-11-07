//
//  GoalTimelineProvider.swift
//  BloomWidgets
//
//  Created by Claude Code on 2025-10-30.
//

import Foundation
import WidgetKit
import AppIntents
import SwiftUI
import BloomFoundation
import BloomUI
import DataContainer
import CoreHealth

struct GoalTimelineProvider: AppIntentTimelineProvider {
  typealias Entry = GoalEntry
  typealias Intent = GoalConfigurationIntent

  func placeholder(in context: Context) -> GoalEntry {
    GoalEntry(
      date: Date(),
      relevance: nil,
      goalId: "placeholder",
      targetMetric: .stepCount,
      currentValue: 7543,
      targetValue: 10000,
      targetUnit: "steps",
      timePeriod: "daily",
      gridData: .daily(placeholderGridModel()),
      isLoading: false
    )
  }

  func snapshot(for configuration: GoalConfigurationIntent, in context: Context) async -> GoalEntry {
    if context.isPreview {
      return placeholder(in: context)
    }
    return await makeEntry(from: configuration)
  }

  func timeline(for configuration: GoalConfigurationIntent, in context: Context) async -> Timeline<GoalEntry> {
    let entry = await makeEntry(from: configuration)

    // Update timeline every hour
    let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    return Timeline(entries: [entry], policy: .after(nextUpdate))
  }

  private func makeEntry(from configuration: GoalConfigurationIntent) async -> GoalEntry {
    // Get selected goal ID from configuration, or use first available goal
    let goalId: String
    if let configuredGoalId = configuration.goal?.id {
      goalId = configuredGoalId
    } else if let firstGoalId = loadFirstGoalId() {
      goalId = firstGoalId
    } else {
      // No goals available at all - show placeholder data
      return GoalEntry(
        date: Date(),
        relevance: nil,
        goalId: "",
        targetMetric: .stepCount,
        currentValue: 0,
        targetValue: 0,
        targetUnit: "",
        timePeriod: "daily",
        gridData: .daily(placeholderGridModel()),
        isLoading: false
      )
    }

    // Load goal data from UserDefaults
    guard let data = UserDefaults.group.data(forKey: "GoalWidgetCache.\(goalId)"),
          let goalData = try? JSONDecoder().decode(GoalWidgetData.self, from: data) else {
      return GoalEntry(
        date: Date(),
        relevance: nil,
        goalId: goalId,
        targetMetric: .stepCount,
        currentValue: 0,
        targetValue: 0,
        targetUnit: "",
        timePeriod: "daily",
        gridData: .daily(GoalGridModel()),
        isLoading: true
      )
    }

    // Convert GoalWidgetData.GridData to GoalEntry.GridData
    let gridData: GoalEntry.GridData
    switch goalData.gridData {
    case .daily(let dailyData):
      let gridModel = GoalGridModel(
        weeks: dailyData.weeks.map { week in
          GoalGridModel.Week(
            id: week.id,
            isComplete: week.isComplete,
            todayIndex: week.todayIndex
          )
        }
      )
      gridData = .daily(gridModel)

    case .weekly(let weeklyData):
      let gridModel = GoalGridWeekModel(
        weeks: weeklyData.weeks.map { week in
          GoalGridWeekModel.Week(
            id: week.id,
            isComplete: week.isComplete,
            isCurrentWeek: week.isCurrentWeek,
            monthLabel: week.monthLabel
          )
        }
      )
      gridData = .weekly(gridModel)

    case .monthly(let monthlyData):
      let gridModel = GoalGridMonthModel(
        months: monthlyData.months.map { month in
          GoalGridMonthModel.Month(
            id: month.id,
            isComplete: month.isComplete,
            isCurrentMonth: month.isCurrentMonth,
            monthLabel: month.monthLabel
          )
        }
      )
      gridData = .monthly(gridModel)

    case .yearly(let yearlyData):
      let gridModel = GoalGridYearModel(
        years: yearlyData.years.map { year in
          GoalGridYearModel.Year(
            id: year.id,
            isComplete: year.isComplete,
            isCurrentYear: year.isCurrentYear,
            yearLabel: year.yearLabel
          )
        }
      )
      gridData = .yearly(gridModel)
    }

    // Convert raw value back to TargetMetric enum
    let targetMetric = TargetMetric(rawValue: goalData.targetMetricRawValue) ?? .stepCount

    return GoalEntry(
      date: Date(),
      relevance: TimelineEntryRelevance(score: 0.8),
      goalId: goalData.id,
      targetMetric: targetMetric,
      currentValue: goalData.currentValue,
      targetValue: goalData.targetValue,
      targetUnit: goalData.targetUnit,
      timePeriod: goalData.timePeriod,
      gridData: gridData,
      isLoading: false
    )
  }

  private func placeholderGridModel() -> GoalGridModel {
    GoalGridModel(
      weeks: [
        GoalGridModel.Week(id: 24, isComplete: [true, false, true, true, false, true, true]),
        GoalGridModel.Week(id: 23, isComplete: [false, true, true, false, true, true, false]),
        GoalGridModel.Week(id: 22, isComplete: [true, true, false, true, true, false, true]),
        GoalGridModel.Week(id: 21, isComplete: [true, true, true, false, true, true, false]),
        GoalGridModel.Week(id: 20, isComplete: [false, true, false, true, true, true, true]),
        GoalGridModel.Week(id: 19, isComplete: [true, false, true, false, true, true, true]),
        GoalGridModel.Week(id: 18, isComplete: [true, true, true, true, false, true, false]),
        GoalGridModel.Week(id: 17, isComplete: [false, true, true, true, true, false, true]),
        GoalGridModel.Week(id: 16, isComplete: [true, true, false, true, false, true, true]),
        GoalGridModel.Week(id: 15, isComplete: [true, false, true, true, true, true, false]),
        GoalGridModel.Week(id: 14, isComplete: [false, true, true, false, true, true, true]),
        GoalGridModel.Week(id: 13, isComplete: [true, true, true, true, false, true, true]),
        GoalGridModel.Week(id: 12, isComplete: [true, false, true, false, true, false, true]),
        GoalGridModel.Week(id: 11, isComplete: [false, true, false, true, true, true, false]),
        GoalGridModel.Week(id: 10, isComplete: [true, true, true, false, true, true, true]),
        GoalGridModel.Week(id: 9, isComplete: [true, false, true, true, false, true, false]),
        GoalGridModel.Week(id: 8, isComplete: [false, true, true, true, true, false, true]),
        GoalGridModel.Week(id: 7, isComplete: [true, true, false, true, false, true, true]),
        GoalGridModel.Week(id: 6, isComplete: [false, true, true, false, true, true, false]),
        GoalGridModel.Week(id: 5, isComplete: [true, false, true, true, false, true, true]),
        GoalGridModel.Week(id: 4, isComplete: [true, true, true, false, true, false, true]),
        GoalGridModel.Week(id: 3, isComplete: [false, true, false, true, true, true, false]),
        GoalGridModel.Week(id: 2, isComplete: [true, false, true, false, true, true, true]),
        GoalGridModel.Week(id: 1, isComplete: [true, true, false, true, false, true, false]),
        GoalGridModel.Week(id: 0, isComplete: [true, true, false, true], todayIndex: 3),
      ]
    )
  }

  /// Loads the first available goal ID from the cache
  private func loadFirstGoalId() -> String? {
    guard let data = UserDefaults.group.data(forKey: "GoalWidgetCache.AllGoals"),
          let goalIds = try? JSONDecoder().decode([String].self, from: data),
          let firstGoalId = goalIds.first else {
      return nil
    }
    return firstGoalId
  }
}
