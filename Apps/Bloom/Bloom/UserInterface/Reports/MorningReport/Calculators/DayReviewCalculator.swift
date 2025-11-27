//
//  DayReviewCalculator.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-22.
//

import Foundation
import DataContainer
import BloomFoundation
import BloomUI

final actor DayReviewCalculator {
  static let shared = DayReviewCalculator()

  private init() { }
}

extension DayReviewCalculator {

  func calculateDayReviewHealthDataString(
    for date: Date,
    enabledCategories: Set<AIHealthCategory>? = nil
  ) async throws -> String {
    let healthData = try await calculateDayReviewHealthData(for: date, enabledCategories: enabledCategories)
    let jsonData = try JSONEncoder.aiContext.encode(healthData)
    return String(data: jsonData, encoding: .utf8) ?? "{}"
  }

  func calculateDayReviewHealthData(
    for date: Date,
    enabledCategories: Set<AIHealthCategory>? = nil
  ) async throws -> DayReviewHealthData {
    // If enabledCategories is provided, use it for filtering. Otherwise, fetch all data (nil = no filtering)
    let shouldFetchDemographicsOrLocation =
      shouldFetch(category: .demographics, enabledCategories: enabledCategories) ||
      shouldFetch(category: .location, enabledCategories: enabledCategories)
    let shouldFetchGoals = shouldFetch(category: .goals, enabledCategories: enabledCategories)
    let shouldFetchWeather = shouldFetch(category: .weather, enabledCategories: enabledCategories)
    let shouldFetchCalendarEvents = shouldFetch(category: .calendarEvents, enabledCategories: enabledCategories)

    // Fetch enabled data concurrently - demographics/location filtered internally by generateDemographics()
    async let demographics = shouldFetchDemographicsOrLocation
      ? ChatVitalConverter.shared.generateDemographics(enabledCategories: enabledCategories)
      : nil
    async let vitals = DayVitalsCalculator.shared.calculateVitals(for: date, enabledCategories: enabledCategories)
    async let goalProgress = shouldFetchGoals ? try GoalProgressCalculator.shared.calculateGoalProgress(for: date) : nil
    async let simplifiedWeather = shouldFetchWeather ? DayReviewWeatherCalculator.shared.calculateSimplifiedWeatherData(for: date) : nil
    async let events = shouldFetchCalendarEvents ? DayReviewEventCalculator.shared.calculateEventData(for: date) : nil

    let (demographicsResult, vitalsResult, goalProgressResult, simplifiedWeatherResult, eventsResult) = await (
      demographics,
      vitals,
      try goalProgress,
      simplifiedWeather,
      events
    )

    return DayReviewHealthData(
      demographics: demographicsResult,
      vitals: vitalsResult,
      goalProgress: goalProgressResult,
      weather: nil,
      simplifiedWeather: simplifiedWeatherResult,
      events: eventsResult
    )
  }

  private func shouldFetch(category: AIHealthCategory, enabledCategories: Set<AIHealthCategory>?) -> Bool {
    guard let enabledCategories = enabledCategories else {
      // No filtering - fetch everything
      return true
    }
    return enabledCategories.contains(category)
  }
}
