//
//  TodayInsightsManager.swift
//  Bloom
//
//  Created by Assistant on 2025-01-25.
//

import Foundation
import SwiftUI
import BloomFoundation
import BloomUI
import DataContainer
import BloomModel
import TelemetryDeck
import CoreNetwork

private extension String {
  static let lastTodayContentResponse = "TodayInsightsManager.lastTodayContentResponse"
  static let budStateOverride = "TodayInsightsManager.budStateOverride"
}

@MainActor @Observable
final class TodayInsightsManager {
  static let shared = TodayInsightsManager()

  var isLoadingContent = false
  var hasLoadError = false

  var budStateOverride: String? {
    didSet {
      if let budStateOverride {
        UserDefaults.standard.set(budStateOverride, forKey: .budStateOverride)
      } else {
        UserDefaults.standard.removeObject(forKey: .budStateOverride)
      }
    }
  }

  private var lastResponse: TodayContentDTO? {
    didSet {
      if let response = lastResponse {
        if let data = try? JSONEncoder().encode(response) {
          UserDefaults.group.set(data, forKey: .lastTodayContentResponse)
          // Reload widget timeline when data updates
          WidgetRefreshManager.shared.reloadTodayWidgets()
          WidgetRefreshManager.shared.reloadHealthInsightWidgets()
          WidgetRefreshManager.shared.reloadBudSummaryWidgets()
        }
      } else {
        UserDefaults.group.removeObject(forKey: .lastTodayContentResponse)
      }
    }
  }

  private init() {
    loadStoredData()
    Task {
      await performOneTimeDataCleanup()
    }
  }

  var todayContent: TodayContentDTO? {
    // Return nil if insights are disabled (keep cached data but don't expose it)
    guard isInsightsEnabled() else {
      return nil
    }

    // Check if stored content is from today
    guard let content = lastResponse,
          Calendar.current.isDate(content.day, inSameDayAs: Date()) else {
      return nil
    }
    return content
  }

  var budState: TodayReportResponse.BudState? {
    // Check for developer override first
    if let overrideRawValue = budStateOverride,
       let overrideState = TodayReportResponse.BudState(rawValue: overrideRawValue) {
      return overrideState
    }

    // Return default BudState when insights are disabled (keep cached data but don't expose it)
    guard isInsightsEnabled() else {
      return .proudCoach
    }

    guard let content = todayContent,
          let data = content.budState.data(using: .utf8),
          let budState = try? JSONDecoder().decode(TodayReportResponse.BudState.self, from: data) else {
      // Return nil when insights enabled but content unavailable
      return nil
    }
    return budState
  }

  func shouldRefreshContent() -> Bool {
    // Early return if insights are disabled
    guard isInsightsEnabled() else {
      internalLog(.todayInsights, "Today Insights disabled in settings, returning false for shouldRefreshContent()")
      return false
    }

    // Check if we have content for today
    guard let content = lastResponse,
          Calendar.current.isDate(content.day, inSameDayAs: .now) else {

      if lastResponse == nil {
        internalLog(.todayInsights, "lastResponse was nil, returning true for shouldRefreshContent()")
      } else {
        internalLog(.todayInsights, "lastResponse was for yesterday, returning true for shouldRefreshContent()")
      }
      return true
    }

    return false
  }

  private func isInsightsEnabled() -> Bool {
    AIFeatureSettings.shared.todayInsightsEnabled
  }

  func refreshContentIfNeeded() async {
    guard EntitlementController.shared.hasBloomPro == true else { return }
    // Check if already loading first to prevent race conditions from concurrent callers
    guard !isLoadingContent else { return }
    guard shouldRefreshContent() else { return }

    await loadTodayContent()
  }

  func forceRefreshContent() async {
    guard EntitlementController.shared.hasBloomPro == true else { return }
    // Don't check isLoadingContent - we want to override stale in-flight requests
    internalLog(.todayInsights, "Forcing refresh of content")
    clearStoredContent()
    await loadTodayContent()
  }

  func clearStoredContent() {
    lastResponse = nil
  }

  private func loadTodayContent() async {
    // Check if insights are enabled before loading
    guard isInsightsEnabled() else {
      internalLog(.todayInsights, "Today Insights disabled, skipping load")
      return
    }

    isLoadingContent = true
    hasLoadError = false

    defer {
      isLoadingContent = false
    }

    internalLog(.todayInsights, "Refreshing content")

    do {
      let today = Date()

      // Generate health context for yesterday (insights are based on previous day's data)
      let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today
      let healthContext = try await DayReviewCalculator.shared.calculateDayReviewHealthDataString(for: yesterday)

      // Get current timezone
      let timezone = TimeZone.current.identifier

      // Create request and call API
      let request = TodayReportRequest(
        healthContext: healthContext,
        currentTime: DateFormatter.mediumDateShortTime.string(from: today),
        timezone: timezone
      )

      let response = try await NetworkRequester.shared.getTodayInsights(request: request)

      // Convert response to TodayContentDTO
      let content = TodayContentDTO(
        day: Calendar.current.startOfDay(for: today),
        timestamp: today,
        summary: response.summary,
        budState: {
          if let data = try? JSONEncoder().encode(response.budState) {
            return String(data: data, encoding: .utf8) ?? ""
          }
          return ""
        }(),
        todaysAdvice: response.todaysAdvice,
        sleepDetails: response.sleepDetails,
        tonightsSleepRecommendations: response.tonightsSleepRecommendations,
        insights: response.insights.map { insight in
          TodayInsightDTO(
            title: insight.title,
            body: insight.body,
            priority: insight.priority
          )
        },
        periodInsight: (response.phaseTip != nil || response.periodForecast != nil) ? PeriodInsightDTO(
          phaseTip: response.phaseTip,
          periodForecast: response.periodForecast
        ) : nil
      )

      lastResponse = content

      internalLog(.todayInsights, "Finished refresh of content")

    } catch {
      hasLoadError = true
      TelemetryDeck.signal(
        "Today Insights Load Error",
        parameters: ["errorMessage": error.localizedDescription]
      )
    }
  }

  private func loadStoredData() {
    // Load last response
    if let data = UserDefaults.group.data(forKey: .lastTodayContentResponse),
       let response = try? JSONDecoder().decode(TodayContentDTO.self, from: data) {
      lastResponse = response
    }

    // Load bud state override
    budStateOverride = UserDefaults.standard.string(forKey: .budStateOverride)
  }

  private func performOneTimeDataCleanup() async {
    let cleanupKey = "TodayInsightsManager.hasPerformedDataCleanup"

    // Check if cleanup has already been performed
    guard !UserDefaults.group.bool(forKey: cleanupKey) else { return }

    // Perform cleanup of old SwiftData records
    do {
      let modelActor = TodayContentModelActor.standard()
      let deletedCount = try await modelActor.deleteAllTodayContent()

      // Mark cleanup as completed
      UserDefaults.group.set(true, forKey: cleanupKey)

      // Only log telemetry if records were actually deleted
      if deletedCount > 0 {
        TelemetryDeck.signal("Today Content SwiftData Cleanup Completed")
      }
    } catch {
      TelemetryDeck.errorOccurred(
        id: "TodayInsightsManager.dataCleanup",
        category: .thrownException,
        message: error.localizedDescription
      )
    }
  }
}
