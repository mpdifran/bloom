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

  func calculateDayReviewHealthDataString(for date: Date) async throws -> String {
    let healthData = try await calculateDayReviewHealthData(for: date)
    let jsonData = try JSONEncoder.aiContext.encode(healthData)
    return String(data: jsonData, encoding: .utf8) ?? "{}"
  }

  func calculateDayReviewHealthData(for date: Date) async throws -> DayReviewHealthData {
    // Privacy check: If Today Insights is disabled, return empty data
    guard await AIFeatureSettings.shared.todayInsightsEnabled else {
      return DayReviewHealthData(
        demographics: nil,
        vitals: nil,
        goalProgress: nil,
        weather: nil,
        simplifiedWeather: nil,
        events: nil
      )
    }

    // Access enabled categories from settings singleton
    let shouldFetchDemographics = await shouldFetch(category: .demographics)
    let shouldFetchLocation = await shouldFetch(category: .location)
    let shouldFetchDemographicsOrLocation = shouldFetchDemographics || shouldFetchLocation
    let shouldFetchGoals = await shouldFetch(category: .goals)
    let shouldFetchWeather = await shouldFetch(category: .weather)
    let shouldFetchCalendarEvents = await shouldFetch(category: .calendarEvents)

    // Fetch enabled data concurrently - demographics/location filtered internally by generateDemographics()
    async let demographics = shouldFetchDemographicsOrLocation
      ? ChatVitalConverter.shared.generateDemographics(enabledCategories: AIDataSharingSettings.shared.enabledCategories)
      : nil
    async let vitals = DayVitalsCalculator.shared.calculateVitals(for: date, enabledCategories: AIDataSharingSettings.shared.enabledCategories)
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

  private func shouldFetch(category: AIHealthCategory) async -> Bool {
    await AIDataSharingSettings.shared.enabledCategories.contains(category)
  }
}
