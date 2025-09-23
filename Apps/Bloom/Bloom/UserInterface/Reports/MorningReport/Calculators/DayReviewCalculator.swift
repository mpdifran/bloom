//
//  DayReviewCalculator.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-22.
//

import Foundation
import DataContainer
import BloomFoundation

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
    async let demographics = ChatVitalConverter.shared.generateDemographics()
    async let vitals = DayVitalsCalculator.shared.calculateVitals(for: date)
    async let goalProgress = GoalProgressCalculator.shared.calculateGoalProgress(for: date)
    async let simplifiedWeather = DayReviewWeatherCalculator.shared.calculateSimplifiedWeatherData(for: date)
    async let events = DayReviewEventCalculator.shared.calculateEventData(for: date)

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

}
