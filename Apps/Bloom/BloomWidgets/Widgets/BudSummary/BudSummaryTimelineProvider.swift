//
//  BudSummaryTimelineProvider.swift
//  BloomWidgets
//
//  Created by Claude Code on 2025-10-19.
//

import Foundation
import WidgetKit
import AppIntents
import SwiftUI
internal import BloomFoundation
import DataContainer
import BloomUI
import CoreHealth

struct BudSummaryTimelineProvider: TimelineProvider {
  typealias Entry = BudSummaryEntry

  func placeholder(in context: Context) -> BudSummaryEntry {
    let settings = TodaySettings()
    let currentTimeMode = TimeMode.current(for: Date(), settings: settings)

    return BudSummaryEntry(
      date: Date(),
      relevance: nil,
      budState: "proudCoach",
      summary: "You're doing great! Keep up the excellent work on your health journey.",
      timeMode: currentTimeMode,
      userName: getUserName(),
      isLoading: false,
      hasError: false,
      isSubscribed: true
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (BudSummaryEntry) -> Void) {
    let entry = makeEntry()
    completion(entry)
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<BudSummaryEntry>) -> Void) {
    let entry = makeEntry()

    // Update timeline every hour to refresh time mode, greeting, and relevance
    let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()

    let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
    completion(timeline)
  }

  private func makeEntry() -> BudSummaryEntry {
    let settings = TodaySettings()
    let currentTimeMode = TimeMode.current(for: Date(), settings: settings)
    let userName = getUserName()
    let isSubscribed = checkSubscriptionStatus()

    // Check subscription status first
    guard isSubscribed else {
      // Not subscribed - show paywall state (no relevance needed)
      return BudSummaryEntry(
        date: Date(),
        relevance: nil,
        budState: nil,
        summary: nil,
        timeMode: currentTimeMode,
        userName: userName,
        isLoading: false,
        hasError: false,
        isSubscribed: false
      )
    }

    // Try to load today's content from UserDefaults
    guard let data = UserDefaults.group.data(forKey: "TodayInsightsManager.lastTodayContentResponse"),
          let content = try? JSONDecoder().decode(TodayContentDTO.self, from: data) else {
      // No content available - show loading state (no relevance needed)
      return BudSummaryEntry(
        date: Date(),
        relevance: nil,
        budState: nil,
        summary: nil,
        timeMode: currentTimeMode,
        userName: userName,
        isLoading: true,
        hasError: false,
        isSubscribed: true
      )
    }

    // Check if content is from today
    guard Calendar.current.isDate(content.day, inSameDayAs: Date()) else {
      // Content is stale - show loading state (no relevance needed)
      return BudSummaryEntry(
        date: Date(),
        relevance: nil,
        budState: nil,
        summary: nil,
        timeMode: currentTimeMode,
        userName: userName,
        isLoading: true,
        hasError: false,
        isSubscribed: true
      )
    }

    // Return entry with content - calculate relevance for actual content
    return BudSummaryEntry(
      date: Date(),
      relevance: calculateRelevance(settings: settings),
      budState: content.budState,
      summary: content.summary,
      timeMode: currentTimeMode,
      userName: userName,
      isLoading: false,
      hasError: false,
      isSubscribed: true
    )
  }

  private func checkSubscriptionStatus() -> Bool {
    // Read simple boolean from UserDefaults (saved by EntitlementController)
    return UserDefaults.group.bool(forKey: "RevenueCat.IsSubscribed")
  }

  private func getUserName() -> String {
    UserDefaults.group.string(forKey: String.HealthDefaults.name.key) ?? ""
  }

  private func calculateRelevance(settings: TodaySettings) -> TimelineEntryRelevance? {
    let calendar = Calendar.current
    let now = Date()
    let currentHour = calendar.component(.hour, from: now)

    // Target is morning start time (wake time)
    let morningStartHour = settings.morningStartHour

    // Calculate hour distance from morning start
    let hourDistance: Int
    if currentHour >= morningStartHour {
      hourDistance = currentHour - morningStartHour
    } else {
      // Before morning start today
      hourDistance = (24 - morningStartHour) + currentHour
    }

    // Calculate relevance score based on proximity to morning
    let score: Float
    if hourDistance <= 2 {
      score = 1.0 // Within 2 hours after wake time
    } else if hourDistance <= 4 {
      score = 0.7 // Within 4 hours after wake time
    } else {
      score = 0.4 // Otherwise (still useful throughout the day)
    }

    // Duration is 1 hour (3600 seconds) to match our timeline update interval
    return TimelineEntryRelevance(score: score, duration: 3600)
  }
}
