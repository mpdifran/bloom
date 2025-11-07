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

struct GoalTimelineProvider: AppIntentTimelineProvider {
  typealias Entry = GoalEntry
  typealias Intent = GoalConfigurationIntent

  func placeholder(in context: Context) -> GoalEntry {
    GoalEntry(
      date: Date(),
      relevance: nil,
      goalId: "placeholder",
      goalName: "Daily Steps",
      systemImage: "figure.walk",
      colorHex: "#FF6B6B",
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
    // Get selected goal ID from configuration
    guard let goalId = configuration.goal?.id else {
      return GoalEntry(
        date: Date(),
        relevance: nil,
        goalId: "",
        goalName: "No Goal Selected",
        systemImage: "chart.line.uptrend.xyaxis",
        colorHex: "#FF6B6B",
        currentValue: 0,
        targetValue: 0,
        targetUnit: "",
        timePeriod: "daily",
        gridData: .daily(GoalGridModel()),
        isLoading: true
      )
    }

    // Load goal data from UserDefaults
    guard let data = UserDefaults.group.data(forKey: "GoalWidgetCache.\(goalId)"),
          let goalData = try? JSONDecoder().decode(GoalWidgetData.self, from: data) else {
      return GoalEntry(
        date: Date(),
        relevance: nil,
        goalId: goalId,
        goalName: "Loading...",
        systemImage: "chart.line.uptrend.xyaxis",
        colorHex: "#FF6B6B",
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

    return GoalEntry(
      date: Date(),
      relevance: TimelineEntryRelevance(score: 0.8),
      goalId: goalData.id,
      goalName: goalData.name,
      systemImage: goalData.systemImage,
      colorHex: goalData.colorHex,
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
        GoalGridModel.Week(id: 3, isComplete: [true, true, false, true, false, true, true]),
        GoalGridModel.Week(id: 2, isComplete: [false, true, true, false, true, true, false]),
        GoalGridModel.Week(id: 1, isComplete: [true, false, true, true, false, true, true]),
        GoalGridModel.Week(id: 0, isComplete: [true, true, false, true], todayIndex: 3),
      ]
    )
  }
}
