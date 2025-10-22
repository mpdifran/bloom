//
//  HealthInsightTimelineProvider.swift
//  BloomWidgets
//
//  Created by Claude Code on 2025-10-22.
//

import Foundation
import WidgetKit
import SwiftUI
internal import BloomFoundation
import DataContainer
import BloomUI

struct HealthInsightTimelineProvider: TimelineProvider {
  typealias Entry = HealthInsightEntry

  func placeholder(in context: Context) -> HealthInsightEntry {
    HealthInsightEntry(
      date: Date(),
      relevance: nil,
      title: "Nutrition Consistency",
      body: "Your protein intake has been steady this week, but consider adding more fiber-rich foods.",
      priority: 8,
      isLoading: false,
      hasError: false,
      isSubscribed: true
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (HealthInsightEntry) -> Void) {
    let entry = makeCurrentEntry()
    completion(entry)
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<HealthInsightEntry>) -> Void) {
    let calendar = Calendar.current
    let now = Date()

    // Check subscription status first
    let isSubscribed = checkSubscriptionStatus()
    guard isSubscribed else {
      // Not subscribed - show upsell view
      let entry = HealthInsightEntry(
        date: now,
        relevance: nil,
        title: "Actionable Health Insights",
        body: "Spot trends in your health data with personalized insights that help you understand what's working.",
        priority: 2,
        isLoading: false,
        hasError: false,
        isSubscribed: false
      )
      let timeline = Timeline(entries: [entry], policy: .atEnd)
      completion(timeline)
      return
    }

    // Try to load today's content from UserDefaults
    guard let data = UserDefaults.group.data(forKey: "TodayInsightsManager.lastTodayContentResponse"),
          let content = try? JSONDecoder().decode(TodayContentDTO.self, from: data) else {
      // No content available - show loading state
      let entry = HealthInsightEntry(
        date: now,
        relevance: nil,
        title: "Health Insights",
        body: "Open the app to load your personalized health insights.",
        priority: 2,
        isLoading: true,
        hasError: false,
        isSubscribed: true
      )
      let timeline = Timeline(entries: [entry], policy: .atEnd)
      completion(timeline)
      return
    }

    // Check if content is from today
    guard calendar.isDate(content.day, inSameDayAs: now) else {
      // Content is stale
      let entry = HealthInsightEntry(
        date: now,
        relevance: nil,
        title: "Health Insights",
        body: "Open the app to refresh your insights for today.",
        priority: 2,
        isLoading: true,
        hasError: false,
        isSubscribed: true
      )
      let timeline = Timeline(entries: [entry], policy: .atEnd)
      completion(timeline)
      return
    }

    // Check if we have insights
    guard !content.insights.isEmpty else {
      // No insights available
      let entry = HealthInsightEntry(
        date: now,
        relevance: nil,
        title: "No Insights Available",
        body: "Check back later for personalized health insights.",
        priority: 5,
        isLoading: false,
        hasError: false,
        isSubscribed: true
      )
      let timeline = Timeline(entries: [entry], policy: .atEnd)
      completion(timeline)
      return
    }

    // Sort insights by priority (highest first)
    let sortedInsights = content.insights.sorted { $0.priority > $1.priority }

    // Generate random offset so multiple widget instances show different insights
    let randomOffset = Int.random(in: 0..<sortedInsights.count)

    // Generate entries for all remaining hours today
    var entries: [HealthInsightEntry] = []
    let endOfDay = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now)!)
    var currentHour = calendar.date(bySetting: .minute, value: 0, of: now) ?? now
    currentHour = calendar.date(bySetting: .second, value: 0, of: currentHour) ?? currentHour

    var hourIndex = calendar.component(.hour, from: now)

    while currentHour < endOfDay {
      let insight = sortedInsights[(hourIndex + randomOffset) % sortedInsights.count]
      let entry = makeEntry(for: insight, at: currentHour)
      entries.append(entry)

      currentHour = calendar.date(byAdding: .hour, value: 1, to: currentHour)!
      hourIndex += 1
    }

    // Refresh timeline at end of day
    let timeline = Timeline(entries: entries, policy: .after(endOfDay))
    completion(timeline)
  }

  private func makeCurrentEntry() -> HealthInsightEntry {
    // Check subscription status first
    let isSubscribed = checkSubscriptionStatus()
    guard isSubscribed else {
      // Not subscribed - show upsell view
      return HealthInsightEntry(
        date: Date(),
        relevance: nil,
        title: "Actionable Health Insights",
        body: "Spot trends in your health data with personalized insights that help you understand what's working.",
        priority: 2,
        isLoading: false,
        hasError: false,
        isSubscribed: false
      )
    }

    // Try to load today's content from UserDefaults
    guard let data = UserDefaults.group.data(forKey: "TodayInsightsManager.lastTodayContentResponse"),
          let content = try? JSONDecoder().decode(TodayContentDTO.self, from: data) else {
      // No content available - show loading state
      return HealthInsightEntry(
        date: Date(),
        relevance: nil,
        title: "Health Insights",
        body: "Open the app to load your personalized health insights.",
        priority: 2,
        isLoading: true,
        hasError: false,
        isSubscribed: true
      )
    }

    // Check if content is from today
    guard Calendar.current.isDate(content.day, inSameDayAs: Date()) else {
      // Content is stale
      return HealthInsightEntry(
        date: Date(),
        relevance: nil,
        title: "Health Insights",
        body: "Open the app to refresh your insights for today.",
        priority: 2,
        isLoading: true,
        hasError: false,
        isSubscribed: true
      )
    }

    // Check if we have insights
    guard !content.insights.isEmpty else {
      // No insights available
      return HealthInsightEntry(
        date: Date(),
        relevance: nil,
        title: "No Insights Available",
        body: "Check back later for personalized health insights.",
        priority: 5,
        isLoading: false,
        hasError: false,
        isSubscribed: true
      )
    }

    // Sort insights by priority (highest first)
    let sortedInsights = content.insights.sorted { $0.priority > $1.priority }

    // Select insight based on current hour (cycles through all insights)
    let currentHour = Calendar.current.component(.hour, from: Date())
    let selectedIndex = currentHour % sortedInsights.count
    let insight = sortedInsights[selectedIndex]

    // Calculate relevance based on priority
    let relevanceScore = Float(insight.priority) / 10.0
    let relevance = TimelineEntryRelevance(score: relevanceScore, duration: 3600)

    return HealthInsightEntry(
      date: Date(),
      relevance: relevance,
      title: insight.title,
      body: insight.body,
      priority: insight.priority,
      isLoading: false,
      hasError: false,
      isSubscribed: true
    )
  }

  private func makeEntry(for insight: TodayInsightDTO, at date: Date) -> HealthInsightEntry {
    // Calculate relevance based on priority
    let relevanceScore = Float(insight.priority) / 10.0
    let relevance = TimelineEntryRelevance(score: relevanceScore, duration: 3600)

    return HealthInsightEntry(
      date: date,
      relevance: relevance,
      title: insight.title,
      body: insight.body,
      priority: insight.priority,
      isLoading: false,
      hasError: false,
      isSubscribed: true
    )
  }

  private func checkSubscriptionStatus() -> Bool {
    // Read simple boolean from UserDefaults (saved by EntitlementController)
    return UserDefaults.group.bool(forKey: "RevenueCat.IsSubscribed")
  }

  private func colorForPriority(_ priority: Int) -> Color {
    if priority < 4 {
      return .mutedBlue
    } else if priority < 8 {
      return .mutedYellow
    } else {
      return .mutedPurple
    }
  }
}
