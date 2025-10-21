//
//  BudSummaryWidget.swift
//  BloomWidgets
//
//  Created by Claude Code on 2025-10-19.
//

import SwiftUI
import WidgetKit
internal import BloomFoundation
import BloomUI

struct BudSummaryWidget: Widget {
  let kind: String = .WidgetKind.budSummary

  var body: some WidgetConfiguration {
    StaticConfiguration(
      kind: kind,
      provider: BudSummaryTimelineProvider()
    ) { entry in
      BudSummaryWidgetView(entry: entry)
    }
    .configurationDisplayName("Bud's Summary")
    .description("See Bud's daily summary of your health.")
    .supportedFamilies([.systemMedium, .systemLarge])
  }
}

#Preview("Medium - Morning", as: .systemMedium) {
  BudSummaryWidget()
} timeline: {
  BudSummaryEntry(
    date: .now,
    relevance: TimelineEntryRelevance(score: 0.7, duration: 3600),
    budState: "proudCoach",
    summary: "You had a strong strength and protein day but overshot calories and sodium while not getting enough cardio or deep sleep.",
    timeMode: .afternoon,
    userName: "Mark",
    isLoading: false,
    hasError: false,
    isSubscribed: true
  )
}

#Preview("Large - Afternoon", as: .systemLarge) {
  BudSummaryWidget()
} timeline: {
  BudSummaryEntry(
    date: .now,
    relevance: TimelineEntryRelevance(score: 0.7, duration: 3600),
    budState: "superhero",
    summary: "Amazing work! You hit all your goals today—excellent nutrition, solid workout, and great sleep quality. Keep up the good work and you'll start to see results!",
    timeMode: .afternoon,
    userName: "Mark",
    isLoading: false,
    hasError: false,
    isSubscribed: true
  )
}

#Preview("Loading", as: .systemMedium) {
  BudSummaryWidget()
} timeline: {
  BudSummaryEntry(
    date: .now,
    relevance: nil,
    budState: nil,
    summary: nil,
    timeMode: .morning,
    userName: "",
    isLoading: true,
    hasError: false,
    isSubscribed: true
  )
}

#Preview("Error - Medium", as: .systemMedium) {
  BudSummaryWidget()
} timeline: {
  BudSummaryEntry(
    date: .now,
    relevance: nil,
    budState: nil,
    summary: nil,
    timeMode: .afternoon,
    userName: "Mark",
    isLoading: false,
    hasError: true,
    isSubscribed: true
  )
}

#Preview("Error - Large", as: .systemLarge) {
  BudSummaryWidget()
} timeline: {
  BudSummaryEntry(
    date: .now,
    relevance: nil,
    budState: nil,
    summary: nil,
    timeMode: .afternoon,
    userName: "Mark",
    isLoading: false,
    hasError: true,
    isSubscribed: true
  )
}

#Preview("Not Subscribed - Medium", as: .systemMedium) {
  BudSummaryWidget()
} timeline: {
  BudSummaryEntry(
    date: .now,
    relevance: nil,
    budState: nil,
    summary: nil,
    timeMode: .morning,
    userName: "",
    isLoading: false,
    hasError: false,
    isSubscribed: false
  )
}

#Preview("Not Subscribed - Large", as: .systemLarge) {
  BudSummaryWidget()
} timeline: {
  BudSummaryEntry(
    date: .now,
    relevance: nil,
    budState: nil,
    summary: nil,
    timeMode: .afternoon,
    userName: "",
    isLoading: false,
    hasError: false,
    isSubscribed: false
  )
}
