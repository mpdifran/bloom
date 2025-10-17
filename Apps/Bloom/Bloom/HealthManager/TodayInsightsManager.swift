//
//  TodayInsightsManager.swift
//  Bloom
//
//  Created by Assistant on 2025-01-25.
//

import Foundation
import SwiftUI
import BloomFoundation
import DataContainer
import BloomModel
import TelemetryDeck
import CoreNetwork

private extension String {
  static let lastTodayContentRequestDate = "TodayInsightsManager.lastTodayContentRequestDate"
  static let lastTodayContentResponse = "TodayInsightsManager.lastTodayContentResponse"
}

@MainActor @Observable
final class TodayInsightsManager {
  static let shared = TodayInsightsManager()

  var isLoadingContent = false
  var hasLoadError = false

  private var lastRequestDate: Date? {
    didSet {
      UserDefaults.group.set(lastRequestDate, forKey: .lastTodayContentRequestDate)
    }
  }

  private var lastResponse: TodayContentDTO? {
    didSet {
      if let response = lastResponse {
        if let data = try? JSONEncoder().encode(response) {
          UserDefaults.group.set(data, forKey: .lastTodayContentResponse)
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
    // Check if stored content is from today
    guard let content = lastResponse,
          Calendar.current.isDate(content.day, inSameDayAs: Date()) else {
      return nil
    }
    return content
  }

  var budState: TodayReportResponse.BudState? {
    guard let content = todayContent,
          let data = content.budState.data(using: .utf8),
          let budState = try? JSONDecoder().decode(TodayReportResponse.BudState.self, from: data) else {
      return nil
    }
    return budState
  }

  func shouldRefreshContent() -> Bool {
    // Check if we have content for today
    guard todayContent != nil else { return true }

    // Check if we have made a request today
    guard let lastRequest = lastRequestDate else { return true }

    return !Calendar.current.isDate(lastRequest, inSameDayAs: Date())
  }

  func refreshContentIfNeeded() async {
    guard shouldRefreshContent() else { return }
    guard !isLoadingContent else { return }

    await loadTodayContent()
  }

  func forceRefreshContent() async {
    guard !isLoadingContent else { return }
    await loadTodayContent()
  }

  func clearStoredContent() {
    lastRequestDate = nil
    lastResponse = nil
  }

  private func loadTodayContent() async {
    isLoadingContent = true
    hasLoadError = false

    defer {
      isLoadingContent = false
    }

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

      lastRequestDate = today
      lastResponse = content

    } catch {
      hasLoadError = true
      TelemetryDeck.signal(
        "Today Insights Load Error",
        parameters: ["errorMessage": error.localizedDescription]
      )
    }
  }

  private func loadStoredData() {
    // Load last request date
    if let date = UserDefaults.group.object(forKey: .lastTodayContentRequestDate) as? Date {
      lastRequestDate = date
    }

    // Load last response
    if let data = UserDefaults.group.data(forKey: .lastTodayContentResponse),
       let response = try? JSONDecoder().decode(TodayContentDTO.self, from: data) {
      lastResponse = response
    }
  }

  private func performOneTimeDataCleanup() async {
    let cleanupKey = "TodayInsightsManager.hasPerformedDataCleanup"

    // Check if cleanup has already been performed
    guard !UserDefaults.group.bool(forKey: cleanupKey) else { return }

    // Perform cleanup of old SwiftData records
    do {
      let modelActor = TodayContentModelActor.standard()
      try await modelActor.deleteAllTodayContent()

      // Mark cleanup as completed
      UserDefaults.group.set(true, forKey: cleanupKey)

      TelemetryDeck.signal("Today Content SwiftData Cleanup Completed")
    } catch {
      TelemetryDeck.errorOccurred(
        id: "TodayInsightsManager.dataCleanup",
        category: .thrownException,
        message: error.localizedDescription
      )
    }
  }
}
