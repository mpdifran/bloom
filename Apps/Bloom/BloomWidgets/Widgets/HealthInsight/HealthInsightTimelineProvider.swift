//
//  HealthInsightTimelineProvider.swift
//  BloomWidgets
//
//  Created by Claude Code on 2025-10-22.
//

import Foundation
import WidgetKit
import SwiftUI
import BloomFoundation
import DataContainer
import BloomUI

struct HealthInsightTimelineProvider: TimelineProvider {
  typealias Entry = HealthInsightEntry

  func placeholder(in context: Context) -> HealthInsightEntry {
    let contentState = TodayContentLoader.loadTodayContent()

    switch contentState {
    case .subscriptionRequired:
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

    case .loading:
      // No content available - show sample data with loading state
      return HealthInsightEntry(
        date: Date(),
        relevance: nil,
        title: "Nutrition Consistency",
        body: "Your protein intake has been steady this week, but consider adding more fiber-rich foods.",
        priority: 8,
        isLoading: true,
        hasError: false,
        isSubscribed: true
      )

    case .loaded(let content):
      // Show real cached insight if available
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

      // Show highest priority insight
      let topInsight = content.insights.sorted { $0.priority > $1.priority }.first!
      return HealthInsightEntry(
        date: Date(),
        relevance: nil,
        title: topInsight.title,
        body: topInsight.body,
        priority: topInsight.priority,
        isLoading: false,
        hasError: false,
        isSubscribed: true
      )
    }
  }

  func getSnapshot(in context: Context, completion: @escaping (HealthInsightEntry) -> Void) {
    let entry = makeCurrentEntry()
    completion(entry)
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<HealthInsightEntry>) -> Void) {
    let calendar = Calendar.current
    let now = Date()
    let contentState = TodayContentLoader.loadTodayContent(for: now)

    // Handle non-loaded states with single entry timeline
    switch contentState {
    case .subscriptionRequired:
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

    case .loading:
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

    case .loaded(let content):
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

      // Continue to generate hourly entries with insights
      generateTimelineEntries(for: content, startingAt: now, calendar: calendar, completion: completion)
    }
  }

  private func generateTimelineEntries(
    for content: TodayContentDTO,
    startingAt now: Date,
    calendar: Calendar,
    completion: @escaping (Timeline<HealthInsightEntry>) -> Void
  ) {

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
    let contentState = TodayContentLoader.loadTodayContent()

    switch contentState {
    case .subscriptionRequired:
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

    case .loading:
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

    case .loaded(let content):
      // Check if we have insights
      guard !content.insights.isEmpty else {
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

}
