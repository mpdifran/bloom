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
    let settings = TodaySettings()
    let currentTimeMode = TimeMode.current(for: Date(), settings: settings)
    let contentState = TodayContentLoader.loadTodayContent()

    switch contentState {
    case .subscriptionRequired:
      return TodayInsightEntry(
        date: Date(),
        relevance: nil,
        title: "Today's Advice",
        content: "Get simple, personalized advice each morning and sleep recommendations each evening to help you thrive with Bloom Plus.",
        symbol: .sparkles,
        color: .mutedOrange,
        contentType: .advice,
        isLoading: false,
        hasError: false,
        isSubscribed: false
      )

    case .loading:
      // No content available - show sample data with loading state
      return TodayInsightEntry(
        date: Date(),
        relevance: nil,
        title: "Today's Advice",
        content: "Focus on getting at least 20 minutes of moderate cardio today to support your VO2 max goals.",
        symbol: .sunHorizonFill,
        color: .mutedOrange,
        contentType: .advice,
        isLoading: true,
        hasError: false,
        isSubscribed: true
      )

    case .loaded(let content):
      // Show real cached content based on time of day
      let shouldShowSleep = currentTimeMode == .evening || currentTimeMode == .night

      if shouldShowSleep {
        return TodayInsightEntry(
          date: Date(),
          relevance: nil,
          title: "Tonight's Sleep",
          content: content.tonightsSleepRecommendations,
          symbol: .moonZzzFill,
          color: .mutedIndigo,
          contentType: .sleep,
          isLoading: false,
          hasError: false,
          isSubscribed: true
        )
      } else {
        return TodayInsightEntry(
          date: Date(),
          relevance: nil,
          title: "Today's Advice",
          content: content.todaysAdvice,
          symbol: .sunHorizonFill,
          color: .mutedOrange,
          contentType: .advice,
          isLoading: false,
          hasError: false,
          isSubscribed: true
        )
      }
    }
  }

  func snapshot(for configuration: TodayInsightConfigurationIntent, in context: Context) async -> TodayInsightEntry {
    makeCurrentEntry(from: configuration)
  }

  func timeline(for configuration: TodayInsightConfigurationIntent, in context: Context) async -> Timeline<TodayInsightEntry> {
    let calendar = Calendar.current
    let now = Date()
    let displayMode = configuration.displayMode ?? .automatic
    let settings = TodaySettings()
    let contentState = TodayContentLoader.loadTodayContent(for: now)

    // Handle non-loaded states with single entry timeline
    switch contentState {
    case .subscriptionRequired:
      let entry = TodayInsightEntry(
        date: now,
        relevance: nil,
        title: "Today's Advice",
        content: "Get simple, personalized advice each morning and sleep recommendations each evening to help you thrive with Bloom Plus.",
        symbol: .sparkles,
        color: .mutedOrange,
        contentType: .advice,
        isLoading: false,
        hasError: false,
        isSubscribed: false
      )
      return Timeline(entries: [entry], policy: .atEnd)

    case .loading:
      let entry = TodayInsightEntry(
        date: now,
        relevance: nil,
        title: "Today's Advice",
        content: "Open the app to load your advice for today.",
        symbol: .sparkles,
        color: .mutedOrange,
        contentType: .advice,
        isLoading: true,
        hasError: false,
        isSubscribed: true
      )
      return Timeline(entries: [entry], policy: .atEnd)

    case .loaded(let content):
      break // Continue to generate hourly entries
    }

    // Extract content from loaded state
    guard case .loaded(let content) = contentState else {
      fatalError("Unexpected state after switch")
    }

    // Generate entries for all remaining hours today
    var entries: [TodayInsightEntry] = []
    let endOfDay = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now)!)
    var currentHour = calendar.date(bySetting: .minute, value: 0, of: now) ?? now
    currentHour = calendar.date(bySetting: .second, value: 0, of: currentHour) ?? currentHour

    while currentHour < endOfDay {
      // Determine which content to show at this hour based on display mode
      let shouldShowSleep: Bool
      switch displayMode {
      case .automatic:
        // Use TodaySettings for time mode detection at this specific hour
        let timeMode = TimeMode.current(for: currentHour, settings: settings)
        shouldShowSleep = timeMode == .evening || timeMode == .night

      case .todaysAdvice:
        shouldShowSleep = false

      case .tonightsSleep:
        shouldShowSleep = true
      }

      let entry = makeEntry(
        for: content,
        at: currentHour,
        showSleep: shouldShowSleep,
        settings: settings
      )
      entries.append(entry)

      currentHour = calendar.date(byAdding: .hour, value: 1, to: currentHour)!
    }

    // Refresh timeline at end of day
    return Timeline(entries: entries, policy: .after(endOfDay))
  }

  private func makeCurrentEntry(from configuration: TodayInsightConfigurationIntent) -> TodayInsightEntry {
    let displayMode = configuration.displayMode ?? .automatic
    let settings = TodaySettings()
    let contentState = TodayContentLoader.loadTodayContent()

    switch contentState {
    case .subscriptionRequired:
      // Not subscribed - show upsell view
      return TodayInsightEntry(
        date: Date(),
        relevance: nil,
        title: "Today's Advice",
        content: "Get simple, personalized advice each morning and sleep recommendations each evening to help you thrive with Bloom Plus.",
        symbol: .sparkles,
        color: .mutedOrange,
        contentType: .advice,
        isLoading: false,
        hasError: false,
        isSubscribed: false
      )

    case .loading:
      // No content available - show loading state
      return TodayInsightEntry(
        date: Date(),
        relevance: nil,
        title: "Today's Advice",
        content: "Open the app to load your advice for today.",
        symbol: .sparkles,
        color: .mutedOrange,
        contentType: .advice,
        isLoading: true,
        hasError: false,
        isSubscribed: true
      )

    case .loaded(let content):
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
          hasError: false,
          isSubscribed: true
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
          hasError: false,
          isSubscribed: true
        )
      }
    }
  }

  private func makeEntry(
    for content: TodayContentDTO,
    at date: Date,
    showSleep: Bool,
    settings: TodaySettings
  ) -> TodayInsightEntry {
    if showSleep {
      // Show tonight's sleep recommendations
      return TodayInsightEntry(
        date: date,
        relevance: calculateRelevance(for: .sleep, at: date, settings: settings),
        title: "Tonight's Sleep",
        content: content.tonightsSleepRecommendations,
        symbol: .moonZzzFill,
        color: .mutedIndigo,
        contentType: .sleep,
        isLoading: false,
        hasError: false,
        isSubscribed: true
      )
    } else {
      // Show today's advice
      return TodayInsightEntry(
        date: date,
        relevance: calculateRelevance(for: .advice, at: date, settings: settings),
        title: "Today's Advice",
        content: content.todaysAdvice,
        symbol: .sunHorizonFill,
        color: .mutedOrange,
        contentType: .advice,
        isLoading: false,
        hasError: false,
        isSubscribed: true
      )
    }
  }

  private func calculateRelevance(
    for contentType: TodayInsightEntry.ContentType,
    at date: Date,
    settings: TodaySettings
  ) -> TimelineEntryRelevance? {
    let calendar = Calendar.current
    let currentHour = calendar.component(.hour, from: date)

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

  private func calculateRelevance(for contentType: TodayInsightEntry.ContentType, settings: TodaySettings) -> TimelineEntryRelevance? {
    // Legacy version for makeCurrentEntry - uses current time
    calculateRelevance(for: contentType, at: Date(), settings: settings)
  }
}
