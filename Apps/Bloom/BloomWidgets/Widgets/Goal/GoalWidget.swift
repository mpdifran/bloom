//
//  GoalWidget.swift
//  BloomWidgets
//
//  Created by Claude Code on 2025-10-30.
//

import SwiftUI
import WidgetKit
import BloomFoundation
import BloomUI

struct GoalWidget: Widget {
  let kind: String = "GoalWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind,
      intent: GoalConfigurationIntent.self,
      provider: GoalTimelineProvider()
    ) { entry in
      GoalWidgetView(entry: entry)
    }
    .configurationDisplayName("Goals")
    .description("Track your goal completion visually over time.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

#Preview("Daily Steps - Small", as: .systemSmall) {
  GoalWidget()
} timeline: {
  GoalEntry(
    date: .now,
    relevance: TimelineEntryRelevance(score: 0.8),
    goalId: "steps",
    goalName: "Steps",
    systemImage: "figure.walk",
    colorHex: "#6BDA6B",
    currentValue: 7543,
    targetValue: 10000,
    targetUnit: "steps",
    timePeriod: "daily",
    gridData: .daily(GoalGridModel(
      weeks: [
        GoalGridModel.Week(id: 7, isComplete: [true, true, false, true, false, true, true]),
        GoalGridModel.Week(id: 6, isComplete: [false, true, true, false, true, true, false]),
        GoalGridModel.Week(id: 5, isComplete: [true, false, true, true, false, true, true]),
        GoalGridModel.Week(id: 4, isComplete: [true, true, true, false, true, false, true]),
        GoalGridModel.Week(id: 3, isComplete: [false, true, false, true, true, true, false]),
        GoalGridModel.Week(id: 2, isComplete: [true, false, true, false, true, true, true]),
        GoalGridModel.Week(id: 1, isComplete: [true, true, false, true, false, true, false]),
        GoalGridModel.Week(id: 0, isComplete: [true, true, false, true], todayIndex: 3),
      ]
    )),
    isLoading: false
  )
}

#Preview("Daily HRZ5 - Medium", as: .systemMedium) {
  GoalWidget()
} timeline: {
  GoalEntry(
    date: .now,
    relevance: TimelineEntryRelevance(score: 0.8),
    goalId: "hrz5",
    goalName: "Heart Rate Zone 5",
    systemImage: "heart.fill",
    colorHex: "#FF4444",
    currentValue: 12,
    targetValue: 20,
    targetUnit: "min",
    timePeriod: "daily",
    gridData: .daily(GoalGridModel(
      weeks: [
        GoalGridModel.Week(id: 24, isComplete: [false, false, false, false, false, false, false]),
        GoalGridModel.Week(id: 23, isComplete: [false, false, false, false, false, false, false]),
        GoalGridModel.Week(id: 22, isComplete: [false, false, false, false, false, false, false]),
        GoalGridModel.Week(id: 21, isComplete: [false, false, false, false, false, false, false]),
        GoalGridModel.Week(id: 20, isComplete: [false, false, false, false, false, false, false]),
        GoalGridModel.Week(id: 19, isComplete: [false, false, false, false, false, false, false]),
        GoalGridModel.Week(id: 18, isComplete: [false, false, false, false, false, false, false]),
        GoalGridModel.Week(id: 17, isComplete: [false, false, false, false, false, false, false]),
        GoalGridModel.Week(id: 16, isComplete: [true, true, false, true, false, true, true]),
        GoalGridModel.Week(id: 15, isComplete: [true, true, false, true, false, true, true]),
        GoalGridModel.Week(id: 14, isComplete: [false, true, true, false, true, true, false]),
        GoalGridModel.Week(id: 13, isComplete: [true, false, true, true, false, true, true]),
        GoalGridModel.Week(id: 12, isComplete: [true, true, true, false, true, false, true]),
        GoalGridModel.Week(id: 11, isComplete: [false, true, false, true, true, true, false]),
        GoalGridModel.Week(id: 10, isComplete: [true, false, true, false, true, true, true]),
        GoalGridModel.Week(id: 9, isComplete: [true, true, false, true, false, true, false]),
        GoalGridModel.Week(id: 8, isComplete: [false, true, true, true, false, true, true]),
        GoalGridModel.Week(id: 7, isComplete: [true, false, false, true, true, false, true]),
        GoalGridModel.Week(id: 6, isComplete: [true, true, true, false, true, true, false]),
        GoalGridModel.Week(id: 5, isComplete: [false, false, true, true, false, true, true]),
        GoalGridModel.Week(id: 4, isComplete: [true, true, false, true, true, true, false]),
        GoalGridModel.Week(id: 3, isComplete: [false, true, true, false, false, true, true]),
        GoalGridModel.Week(id: 2, isComplete: [true, false, true, true, true, false, false]),
        GoalGridModel.Week(id: 1, isComplete: [true, true, false, true, false, true, false]),
        GoalGridModel.Week(id: 0, isComplete: [true, true, false, true], todayIndex: 3),
      ]
    )),
    isLoading: false
  )
}

#Preview("Weekly Workouts - Small", as: .systemSmall) {
  GoalWidget()
} timeline: {
  GoalEntry(
    date: .now,
    relevance: TimelineEntryRelevance(score: 0.8),
    goalId: "workouts",
    goalName: "Workouts",
    systemImage: "figure.run",
    colorHex: "#FF9500",
    currentValue: 3,
    targetValue: 5,
    targetUnit: "workouts",
    timePeriod: "weekly",
    gridData: .weekly(GoalGridWeekModel(
      weeks: [
        GoalGridWeekModel.Week(id: 0, isComplete: false),
        GoalGridWeekModel.Week(id: 1, isComplete: true),
        GoalGridWeekModel.Week(id: 2, isComplete: false),
        GoalGridWeekModel.Week(id: 3, isComplete: true, monthLabel: "Apr"),
        GoalGridWeekModel.Week(id: 4, isComplete: false),
        GoalGridWeekModel.Week(id: 5, isComplete: true),
        GoalGridWeekModel.Week(id: 6, isComplete: false),
        GoalGridWeekModel.Week(id: 7, isComplete: true),
        GoalGridWeekModel.Week(id: 8, isComplete: true, monthLabel: "May"),
        GoalGridWeekModel.Week(id: 9, isComplete: false),
        GoalGridWeekModel.Week(id: 10, isComplete: true),
        GoalGridWeekModel.Week(id: 11, isComplete: false),
        GoalGridWeekModel.Week(id: 12, isComplete: true),
        GoalGridWeekModel.Week(id: 13, isComplete: true),
        GoalGridWeekModel.Week(id: 14, isComplete: false, monthLabel: "Jun"),
        GoalGridWeekModel.Week(id: 15, isComplete: true),
        GoalGridWeekModel.Week(id: 16, isComplete: false),
        GoalGridWeekModel.Week(id: 17, isComplete: true),
        GoalGridWeekModel.Week(id: 18, isComplete: true),
        GoalGridWeekModel.Week(id: 19, isComplete: false, isCurrentWeek: true, monthLabel: "Jul"),
      ]
    )),
    isLoading: false
  )
}

#Preview("Weekly Workouts - Medium", as: .systemMedium) {
  GoalWidget()
} timeline: {
  GoalEntry(
    date: .now,
    relevance: TimelineEntryRelevance(score: 0.8),
    goalId: "workouts",
    goalName: "Workouts",
    systemImage: "figure.run",
    colorHex: "#FF9500",
    currentValue: 3,
    targetValue: 5,
    targetUnit: "workouts",
    timePeriod: "weekly",
    gridData: .weekly(GoalGridWeekModel(
      weeks: [
        GoalGridWeekModel.Week(id: 0, isComplete: false),
        GoalGridWeekModel.Week(id: 1, isComplete: true),
        GoalGridWeekModel.Week(id: 2, isComplete: false),
        GoalGridWeekModel.Week(id: 3, isComplete: true, monthLabel: "Apr"),
        GoalGridWeekModel.Week(id: 4, isComplete: false),
        GoalGridWeekModel.Week(id: 5, isComplete: true),
        GoalGridWeekModel.Week(id: 6, isComplete: false),
        GoalGridWeekModel.Week(id: 7, isComplete: true),
        GoalGridWeekModel.Week(id: 8, isComplete: true, monthLabel: "May"),
        GoalGridWeekModel.Week(id: 9, isComplete: false),
        GoalGridWeekModel.Week(id: 10, isComplete: true),
        GoalGridWeekModel.Week(id: 11, isComplete: false),
        GoalGridWeekModel.Week(id: 12, isComplete: true),
        GoalGridWeekModel.Week(id: 13, isComplete: true),
        GoalGridWeekModel.Week(id: 14, isComplete: false, monthLabel: "Jun"),
        GoalGridWeekModel.Week(id: 15, isComplete: true),
        GoalGridWeekModel.Week(id: 16, isComplete: false),
        GoalGridWeekModel.Week(id: 17, isComplete: true),
        GoalGridWeekModel.Week(id: 18, isComplete: true),
        GoalGridWeekModel.Week(id: 19, isComplete: false, isCurrentWeek: true, monthLabel: "Jul"),
      ]
    )),
    isLoading: false
  )
}

#Preview("Monthly Sleep - Small", as: .systemSmall) {
  GoalWidget()
} timeline: {
  GoalEntry(
    date: .now,
    relevance: TimelineEntryRelevance(score: 0.8),
    goalId: "sleep",
    goalName: "Sleep",
    systemImage: "bed.double.fill",
    colorHex: "#5E5CE6",
    currentValue: 178,
    targetValue: 200,
    targetUnit: "hours",
    timePeriod: "monthly",
    gridData: .monthly(GoalGridMonthModel(
      months: [
        GoalGridMonthModel.Month(id: 0, isComplete: false,  monthLabel: "Jan"),
        GoalGridMonthModel.Month(id: 1, isComplete: false, monthLabel: "Feb"),
        GoalGridMonthModel.Month(id: 2, isComplete: true, monthLabel: "Mar"),
        GoalGridMonthModel.Month(id: 3, isComplete: false, monthLabel: "Apr"),
        GoalGridMonthModel.Month(id: 4, isComplete: true, monthLabel: "May"),
        GoalGridMonthModel.Month(id: 5, isComplete: true, monthLabel: "Jun"),
        GoalGridMonthModel.Month(id: 6, isComplete: false, monthLabel: "Jul"),
        GoalGridMonthModel.Month(id: 7, isComplete: true, monthLabel: "Aug"),
        GoalGridMonthModel.Month(id: 8, isComplete: false, monthLabel: "Sep"),
        GoalGridMonthModel.Month(id: 9, isComplete: true, monthLabel: "Oct"),
        GoalGridMonthModel.Month(id: 10, isComplete: true, monthLabel: "Nov"),
        GoalGridMonthModel.Month(id: 11, isComplete: false, isCurrentMonth: true, monthLabel: "Dec"),
      ]
    )),
    isLoading: false
  )
}

#Preview("Monthly Sleep - Medium", as: .systemMedium) {
  GoalWidget()
} timeline: {
  GoalEntry(
    date: .now,
    relevance: TimelineEntryRelevance(score: 0.8),
    goalId: "sleep",
    goalName: "Sleep",
    systemImage: "bed.double.fill",
    colorHex: "#5E5CE6",
    currentValue: 178,
    targetValue: 200,
    targetUnit: "hours",
    timePeriod: "monthly",
    gridData: .monthly(GoalGridMonthModel(
      months: [
        GoalGridMonthModel.Month(id: 0, isComplete: false, monthLabel: "Jan"),
        GoalGridMonthModel.Month(id: 1, isComplete: false, monthLabel: "Feb"),
        GoalGridMonthModel.Month(id: 2, isComplete: true, monthLabel: "Mar"),
        GoalGridMonthModel.Month(id: 3, isComplete: false, monthLabel: "Apr"),
        GoalGridMonthModel.Month(id: 4, isComplete: true, monthLabel: "May"),
        GoalGridMonthModel.Month(id: 5, isComplete: true, monthLabel: "Jun"),
        GoalGridMonthModel.Month(id: 6, isComplete: false, monthLabel: "Jul"),
        GoalGridMonthModel.Month(id: 7, isComplete: true, monthLabel: "Aug"),
        GoalGridMonthModel.Month(id: 8, isComplete: false, monthLabel: "Sep"),
        GoalGridMonthModel.Month(id: 9, isComplete: true, monthLabel: "Oct"),
        GoalGridMonthModel.Month(id: 10, isComplete: true, monthLabel: "Nov"),
        GoalGridMonthModel.Month(id: 11, isComplete: false, isCurrentMonth: true, monthLabel: "Dec"),
      ]
    )),
    isLoading: false
  )
}

#Preview("Yearly Steps - Medium", as: .systemMedium) {
  GoalWidget()
} timeline: {
  GoalEntry(
    date: .now,
    relevance: TimelineEntryRelevance(score: 0.8),
    goalId: "yearly-steps",
    goalName: "Steps",
    systemImage: "figure.walk",
    colorHex: "#32D74B",
    currentValue: 2800000,
    targetValue: 3650000,
    targetUnit: "steps",
    timePeriod: "yearly",
    gridData: .yearly(GoalGridYearModel(
      years: [
        GoalGridYearModel.Year(id: 0, isComplete: false, yearLabel: "2021"),
        GoalGridYearModel.Year(id: 1, isComplete: false, yearLabel: "2022"),
        GoalGridYearModel.Year(id: 2, isComplete: true, yearLabel: "2023"),
        GoalGridYearModel.Year(id: 3, isComplete: true, yearLabel: "2024"),
        GoalGridYearModel.Year(id: 4, isComplete: false, isCurrentYear: true, yearLabel: "2025"),
      ]
    )),
    isLoading: false
  )
}

#Preview("Loading - Small", as: .systemSmall) {
  GoalWidget()
} timeline: {
  GoalEntry(
    date: .now,
    relevance: nil,
    goalId: "",
    goalName: "Steps",
    systemImage: "figure.walk",
    colorHex: "#FF6B6B",
    currentValue: 0,
    targetValue: 0,
    targetUnit: "",
    timePeriod: "daily",
    gridData: .daily(GoalGridModel()),
    isLoading: true
  )
}

#Preview("Loading - Medium", as: .systemMedium) {
  GoalWidget()
} timeline: {
  GoalEntry(
    date: .now,
    relevance: nil,
    goalId: "",
    goalName: "Steps",
    systemImage: "figure.walk",
    colorHex: "#FF6B6B",
    currentValue: 0,
    targetValue: 0,
    targetUnit: "",
    timePeriod: "daily",
    gridData: .daily(GoalGridModel()),
    isLoading: true
  )
}
