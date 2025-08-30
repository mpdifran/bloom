//
//  TodayContentCoordinator.swift
//  Bloom
//
//  Created by Assistant on 2025-08-29.
//

import Foundation
import CoreHealth
import DataContainer
import BloomModel
import BloomFoundation
import TelemetryDeck

private extension String {
  static let lastTodayContentLoadDate = "TodayContentCoordinator.lastTodayContentLoadDate"
}

final actor TodayContentCoordinator {
  static let shared = TodayContentCoordinator()

  private var lastLoadDate: Date? {
    didSet {
      UserDefaults.group.set(lastLoadDate, forKey: .lastTodayContentLoadDate)
    }
  }
  
  @AsyncStreamable private var isGeneratingContent = false
  @AsyncStreamable private var lastLoadError: Error? = nil
  
  private init() {
    if let date = UserDefaults.group.object(forKey: .lastTodayContentLoadDate) as? Date {
      self.lastLoadDate = date
    }
  }
}

extension TodayContentCoordinator {
  
  var isLoadingContentStream: AsyncStream<Bool> {
    $isGeneratingContent
  }
  
  var errorStream: AsyncStream<Error?> {
    $lastLoadError
  }
  
  func shouldLoadContent() async -> Bool {
    // Check if user has Bloom Plus entitlement
    guard await EntitlementController.shared.hasBloomPro == true else { return false }
    
    // Check if we already have content for today's calendar day
    let contentModelActor = TodayContentModelActor.standard()
    if await contentModelActor.hasContentForToday() {
      return false
    }
    
    return true
  }
  
  func loadContentIfNeeded() async {
    guard await shouldLoadContent() else { return }
    guard !isGeneratingContent else { return }
    
    await generateAndStoreTodayContent()
  }
  
  private func forceReloadContent() async {
    // Private method - only for internal use (sleep data updates)
    // Check if user has Bloom Plus entitlement
    guard await EntitlementController.shared.hasBloomPro == true else { return }
    guard !isGeneratingContent else { return }
    
    await generateAndStoreTodayContent()
  }
  
  func didDetectNewSleepData() async {
    // Check if user has Bloom Plus entitlement
    guard await EntitlementController.shared.hasBloomPro == true else { return }
    
    // Always reload content when new sleep data is available
    // This can happen multiple times per day as sleep data comes in phases
    await forceReloadContent()
  }
  
  var isLoadingContent: Bool {
    isGeneratingContent
  }
  
  func deleteTodaysContent() async throws {
    let contentModelActor = TodayContentModelActor.standard()
    try await contentModelActor.deleteContent(for: Date())
    lastLoadDate = nil
  }
  
  private func generateAndStoreTodayContent() async {
    // Check if user has Bloom Plus entitlement
    guard await EntitlementController.shared.hasBloomPro == true else { return }
    
    isGeneratingContent = true
    lastLoadError = nil
    
    defer {
      isGeneratingContent = false
    }
    
    do {
      let today = Date()
      let contentModelActor = TodayContentModelActor.standard()
      
      // Generate health context for yesterday (insights are based on previous day's data)
      let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today
      let healthContext = try await DayReviewCalculator.shared.calculateDayReviewHealthDataString(for: yesterday)
      
      // Get current timezone
      let timezone = TimeZone.current.identifier
      
      // Create request and call API
      let request = TodayReportRequest(
        healthContext: healthContext,
        currentTime: ISO8601DateFormatter().string(from: today),
        timezone: timezone
      )
      
      let response: TodayReportResponse
      do {
        response = try await NetworkRequester.shared.getTodayInsights(request: request)
      } catch {
        TelemetryDeck.signal(
          "Today Content Network Error",
          parameters: ["errorMessage": error.localizedDescription]
        )
        throw error
      }
      
      // Store the content in SwiftData
      let insights = response.insights.map { insight in
        (title: insight.title, body: insight.body, priority: insight.priority)
      }
      let _ = try await contentModelActor.saveContent(
        for: today,
        summary: response.summary,
        budState: response.budState.rawValue,
        todaysAdvice: response.todaysAdvice,
        sleepDetails: response.sleepDetails,
        tonightsSleepRecommendations: response.tonightsSleepRecommendations,
        insights: insights
      )
      
      lastLoadDate = today
      
      TelemetryDeck.signal("Generated Today Content")
      
    } catch {
      lastLoadError = error
      TelemetryDeck.errorOccurred(
        id: "TodayContentCoordinator.generateAndStoreTodayContent",
        category: .thrownException,
        message: error.localizedDescription
      )
    }
  }
}
