//
//  HealthInsightWidget.swift
//  BloomWidgets
//
//  Created by Claude Code on 2025-10-22.
//

import SwiftUI
import WidgetKit
internal import BloomFoundation

struct HealthInsightWidget: Widget {
  let kind: String = .WidgetKind.healthInsight

  var body: some WidgetConfiguration {
    StaticConfiguration(
      kind: kind,
      provider: HealthInsightTimelineProvider()
    ) { entry in
      HealthInsightWidgetView(entry: entry)
    }
    .configurationDisplayName("Health Insights")
    .description("View personalized health insights that automatically cycle throughout the day.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

#Preview("High Priority", as: .systemMedium) {
  HealthInsightWidget()
} timeline: {
  HealthInsightEntry(
    date: .now,
    relevance: TimelineEntryRelevance(score: 0.9, duration: 3600),
    title: "Nutrition Consistency",
    body: "Your protein intake has been steady this week, but consider adding more fiber-rich foods.",
    priority: 9,
    isLoading: false,
    hasError: false,
    isSubscribed: true
  )
}

#Preview("Medium Priority", as: .systemMedium) {
  HealthInsightWidget()
} timeline: {
  HealthInsightEntry(
    date: .now,
    relevance: TimelineEntryRelevance(score: 0.6, duration: 3600),
    title: "Hydration Goal",
    body: "You're 20% below your daily water intake target. Try to drink more water this afternoon.",
    priority: 6,
    isLoading: false,
    hasError: false,
    isSubscribed: true
  )
}

#Preview("Low Priority", as: .systemMedium) {
  HealthInsightWidget()
} timeline: {
  HealthInsightEntry(
    date: .now,
    relevance: TimelineEntryRelevance(score: 0.2, duration: 3600),
    title: "Great Sleep",
    body: "You got 8 hours of quality sleep last night.",
    priority: 2,
    isLoading: false,
    hasError: false,
    isSubscribed: true
  )
}

#Preview("Small High Priority", as: .systemSmall) {
  HealthInsightWidget()
} timeline: {
  HealthInsightEntry(
    date: .now,
    relevance: TimelineEntryRelevance(score: 0.9, duration: 3600),
    title: "Nutrition Consistency",
    body: "Your protein intake has been steady this week, but consider adding more fiber-rich foods.",
    priority: 9,
    isLoading: false,
    hasError: false,
    isSubscribed: true
  )
}

#Preview("Not Subscribed", as: .systemMedium) {
  HealthInsightWidget()
} timeline: {
  HealthInsightEntry(
    date: .now,
    relevance: nil,
    title: "Actionable Health Insights",
    body: "Spot trends in your health data with personalized insights that help you understand what's working.",
    priority: 8,
    isLoading: false,
    hasError: false,
    isSubscribed: false
  )
}

#Preview("Loading", as: .systemMedium) {
  HealthInsightWidget()
} timeline: {
  HealthInsightEntry(
    date: .now,
    relevance: nil,
    title: "Health Insights",
    body: "Open the app to load your personalized health insights.",
    priority: 5,
    isLoading: true,
    hasError: false,
    isSubscribed: true
  )
}
