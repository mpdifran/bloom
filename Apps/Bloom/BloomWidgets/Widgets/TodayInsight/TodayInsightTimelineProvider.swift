//
//  TodayInsightTimelineProvider.swift
//  BloomWidgets
//
//  Created by Claude Code on 2025-10-19.
//

import Foundation
import WidgetKit
import AppIntents
import SwiftUI
import SFSafeSymbols
internal import BloomFoundation
import DataContainer
import BloomUI

struct TodayInsightTimelineProvider: AppIntentTimelineProvider {
  typealias Entry = TodayInsightEntry
  typealias Intent = TodayInsightConfigurationIntent

  func placeholder(in context: Context) -> TodayInsightEntry {
    TodayInsightEntry(
      date: Date(),
      relevance: nil,
      title: "Today's Advice",
      content: "Focus on getting at least 20 minutes of moderate cardio today to support your VO2 max goals.",
      symbol: .sunHorizonFill,
      color: .mutedOrange,
      contentType: .advice,
      isLoading: false,
      hasError: false
    )
  }

  func snapshot(for configuration: TodayInsightConfigurationIntent, in context: Context) async -> TodayInsightEntry {
    makeEntry(from: configuration)
  }

  func timeline(for configuration: TodayInsightConfigurationIntent, in context: Context) async -> Timeline<TodayInsightEntry> {
    let entry = makeEntry(from: configuration)

    // Update timeline every hour to refresh automatic mode selection and relevance
    let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()

    return Timeline(entries: [entry], policy: .after(nextUpdate))
  }

  private func makeEntry(from configuration: TodayInsightConfigurationIntent) -> TodayInsightEntry {
    let displayMode = configuration.displayMode ?? .automatic
    let settings = TodaySettings()

    // Try to load today's content from UserDefaults
    guard let data = UserDefaults.group.data(forKey: "TodayInsightsManager.lastTodayContentResponse"),
          let content = try? JSONDecoder().decode(TodayContentDTO.self, from: data) else {
      // No content available - show loading state
      return TodayInsightEntry(
        date: Date(),
        relevance: calculateRelevance(for: .advice, settings: settings),
        title: "Today's Insight",
        content: "Open the app to load your personalized insights.",
        symbol: .sparkles,
        color: .mutedOrange,
        contentType: .advice,
        isLoading: true,
        hasError: false
      )
    }

    // Check if content is from today
    guard Calendar.current.isDate(content.day, inSameDayAs: Date()) else {
      // Content is stale
      return TodayInsightEntry(
        date: Date(),
        relevance: calculateRelevance(for: .advice, settings: settings),
        title: "Today's Insight",
        content: "Open the app to refresh your insights for today.",
        symbol: .sparkles,
        color: .mutedOrange,
        contentType: .advice,
        isLoading: true,
        hasError: false
      )
    }

    // Determine which content to show based on display mode
    let shouldShowSleep: Bool
    switch displayMode {
    case .automatic:
      // Use default TodaySettings for time mode detection
      let currentTimeMode = TimeMode.current(for: Date(), settings: settings)
      shouldShowSleep = currentTimeMode == .evening || currentTimeMode == .night

    case .todaysAdvice:
      shouldShowSleep = false

    case .tonightsSleep:
      shouldShowSleep = true
    }

    if shouldShowSleep {
      // Show tonight's sleep recommendations
      return TodayInsightEntry(
        date: Date(),
        relevance: calculateRelevance(for: .sleep, settings: settings),
        title: "Tonight's Sleep",
        content: content.tonightsSleepRecommendations,
        symbol: .moonZzzFill,
        color: .mutedIndigo,
        contentType: .sleep,
        isLoading: false,
        hasError: false
      )
    } else {
      // Show today's advice
      return TodayInsightEntry(
        date: Date(),
        relevance: calculateRelevance(for: .advice, settings: settings),
        title: "Today's Advice",
        content: content.todaysAdvice,
        symbol: .sunHorizonFill,
        color: .mutedOrange,
        contentType: .advice,
        isLoading: false,
        hasError: false
      )
    }
  }

  private func calculateRelevance(for contentType: TodayInsightEntry.ContentType, settings: TodaySettings) -> TimelineEntryRelevance? {
    let calendar = Calendar.current
    let now = Date()
    let currentHour = calendar.component(.hour, from: now)

    // Determine target hour based on content type
    let targetHour: Int
    switch contentType {
    case .sleep:
      // For sleep content, target is near bedtime (nightStartHour)
      targetHour = settings.nightStartHour
    case .advice:
      // For advice content, target is near wake time (morningStartHour)
      targetHour = settings.morningStartHour
    }

    // Calculate hour distance (accounting for day wraparound)
    let hourDistance: Int
    if currentHour >= targetHour {
      hourDistance = currentHour - targetHour
    } else {
      // Next day's target
      hourDistance = (24 - targetHour) + currentHour
    }

    // Calculate relevance score based on proximity to target time
    let score: Float
    if hourDistance <= 1 {
      score = 1.0 // Within 1 hour
    } else if hourDistance <= 2 {
      score = 0.7 // Within 2 hours
    } else {
      score = 0.3 // Otherwise
    }

    // Duration is 1 hour (3600 seconds) to match our timeline update interval
    return TimelineEntryRelevance(score: score, duration: 3600)
  }
}
