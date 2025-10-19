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
      title: "Today's Advice",
      content: "Focus on getting at least 20 minutes of moderate cardio today to support your VO2 max goals.",
      symbol: .sunHorizonFill,
      color: .mutedOrange,
      isLoading: false,
      hasError: false
    )
  }

  func snapshot(for configuration: TodayInsightConfigurationIntent, in context: Context) async -> TodayInsightEntry {
    makeEntry(from: configuration)
  }

  func timeline(for configuration: TodayInsightConfigurationIntent, in context: Context) async -> Timeline<TodayInsightEntry> {
    let entry = makeEntry(from: configuration)

    // Update timeline every hour to refresh automatic mode selection
    let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()

    return Timeline(entries: [entry], policy: .after(nextUpdate))
  }

  private func makeEntry(from configuration: TodayInsightConfigurationIntent) -> TodayInsightEntry {
    let displayMode = configuration.displayMode ?? .automatic

    // Try to load today's content from UserDefaults
    guard let data = UserDefaults.group.data(forKey: "TodayInsightsManager.lastTodayContentResponse"),
          let content = try? JSONDecoder().decode(TodayContentDTO.self, from: data) else {
      // No content available - show loading state
      return TodayInsightEntry(
        date: Date(),
        title: "Today's Insight",
        content: "Open the app to load your personalized insights.",
        symbol: .sparkles,
        color: .mutedOrange,
        isLoading: true,
        hasError: false
      )
    }

    // Check if content is from today
    guard Calendar.current.isDate(content.day, inSameDayAs: Date()) else {
      // Content is stale
      return TodayInsightEntry(
        date: Date(),
        title: "Today's Insight",
        content: "Open the app to refresh your insights for today.",
        symbol: .sparkles,
        color: .mutedOrange,
        isLoading: true,
        hasError: false
      )
    }

    // Determine which content to show based on display mode
    let shouldShowSleep: Bool
    switch displayMode {
    case .automatic:
      // Use default TodaySettings for time mode detection
      let settings = TodaySettings()
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
        title: "Tonight's Sleep",
        content: content.tonightsSleepRecommendations,
        symbol: .moonZzzFill,
        color: .mutedIndigo,
        isLoading: false,
        hasError: false
      )
    } else {
      // Show today's advice
      return TodayInsightEntry(
        date: Date(),
        title: "Today's Advice",
        content: content.todaysAdvice,
        symbol: .sunHorizonFill,
        color: .mutedOrange,
        isLoading: false,
        hasError: false
      )
    }
  }
}
