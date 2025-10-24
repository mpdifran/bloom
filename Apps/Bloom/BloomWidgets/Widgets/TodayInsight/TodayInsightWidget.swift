//
//  TodayInsightWidget.swift
//  BloomWidgets
//
//  Created by Claude Code on 2025-10-19.
//

import SwiftUI
import WidgetKit
import SFSafeSymbols
import BloomFoundation

struct TodayInsightWidget: Widget {
  let kind: String = .WidgetKind.todayInsight

  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind,
      intent: TodayInsightConfigurationIntent.self,
      provider: TodayInsightTimelineProvider()
    ) { entry in
      TodayInsightWidgetView(entry: entry)
    }
    .configurationDisplayName("Daily Insights")
    .description("View your personalized today's advice or tonight's sleep recommendations.")
    .supportedFamilies([.systemMedium])
  }
}

#Preview("Today's Advice", as: .systemMedium) {
  TodayInsightWidget()
} timeline: {
  TodayInsightEntry(
    date: .now,
    relevance: TimelineEntryRelevance(score: 1.0, duration: 3600),
    title: "Today's Advice",
    content: "Focus on getting at least 20 minutes of moderate cardio today—go for a brisk bike ride or jog—to boost your weekly cardio minutes and support your VO2 max goal.",
    symbol: .sunHorizonFill,
    color: .mutedOrange,
    contentType: .advice,
    isLoading: false,
    hasError: false,
    isSubscribed: true
  )
}

#Preview("Tonight's Sleep", as: .systemMedium) {
  TodayInsightWidget()
} timeline: {
  TodayInsightEntry(
    date: .now,
    relevance: TimelineEntryRelevance(score: 1.0, duration: 3600),
    title: "Tonight's Sleep",
    content: "Wind down at least 60 minutes before bed: dim lights, put away screens, and skip the evening ice cream. Aim for a cooler room (around 18–19°C) and consider a short relaxation exercise to help you fall into deeper sleep.",
    symbol: .moonZzzFill,
    color: .mutedIndigo,
    contentType: .sleep,
    isLoading: false,
    hasError: false,
    isSubscribed: true
  )
}

#Preview("Not Subscribed", as: .systemMedium) {
  TodayInsightWidget()
} timeline: {
  TodayInsightEntry(
    date: .now,
    relevance: nil,
    title: "Daily Health Guidance",
    content: "Get simple, personalized advice each morning and sleep recommendations each evening to help you thrive.",
    symbol: .sparkles,
    color: .mutedOrange,
    contentType: .advice,
    isLoading: false,
    hasError: false,
    isSubscribed: false
  )
}

#Preview("Loading", as: .systemMedium) {
  TodayInsightWidget()
} timeline: {
  TodayInsightEntry(
    date: .now,
    relevance: nil,
    title: "Today's Insight",
    content: "Open the app to load your personalized insights.",
    symbol: .sparkles,
    color: .mutedOrange,
    contentType: .advice,
    isLoading: true,
    hasError: false,
    isSubscribed: true
  )
}
