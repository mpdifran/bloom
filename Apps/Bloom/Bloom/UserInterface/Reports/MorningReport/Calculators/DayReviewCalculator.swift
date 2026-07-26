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
import CoreHealth
import CoreNetwork

final actor DayReviewCalculator {
  static let shared = DayReviewCalculator()

  private let healthDefaults = HealthDefaults.shared

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
        events: nil,
        biologicalAgeDiff: nil,
        monitorAlerts: nil
      )
    }

    // Access enabled categories from settings singleton
    let enabledCategories = await AIDataSharingSettings.shared.enabledCategories
    let shouldFetchDemographics = await shouldFetch(category: .demographics)
    let shouldFetchLocation = await shouldFetch(category: .location)
    let shouldFetchDemographicsOrLocation = shouldFetchDemographics || shouldFetchLocation
    let shouldFetchGoals = await shouldFetch(category: .goals)
    let shouldFetchWeather = await shouldFetch(category: .weather)
    let shouldFetchCalendarEvents = await shouldFetch(category: .calendarEvents)

    // Fetch enabled data concurrently - demographics/location filtered internally by generateDemographics()
    async let demographics = shouldFetchDemographicsOrLocation
      ? ChatVitalConverter.shared.generateDemographics(enabledCategories: enabledCategories)
      : nil
    async let vitals = DayVitalsCalculator.shared.calculateVitals(for: date, enabledCategories: enabledCategories)
    async let goalProgress = shouldFetchGoals ? try GoalProgressCalculator.shared.calculateGoalProgress(for: date) : nil
    async let simplifiedWeather = shouldFetchWeather ? DayReviewWeatherCalculator.shared.calculateSimplifiedWeatherData(for: date) : nil
    async let events = shouldFetchCalendarEvents ? DayReviewEventCalculator.shared.calculateEventData(for: date) : nil
    async let bioAgeDiff = generateBiologicalAgeDiff(for: date, enabledCategories: enabledCategories)
    async let monitorAlerts = fetchMonitorAlerts(enabledCategories: enabledCategories)

    let (demographicsResult, vitalsResult, goalProgressResult, simplifiedWeatherResult, eventsResult, bioAgeDiffResult, monitorAlertsResult) = await (
      demographics,
      vitals,
      try goalProgress,
      simplifiedWeather,
      events,
      bioAgeDiff,
      monitorAlerts
    )

    return DayReviewHealthData(
      demographics: demographicsResult,
      vitals: vitalsResult,
      goalProgress: goalProgressResult,
      weather: nil,
      simplifiedWeather: simplifiedWeatherResult,
      events: eventsResult,
      biologicalAgeDiff: bioAgeDiffResult,
      monitorAlerts: monitorAlertsResult
    )
  }

  private func shouldFetch(category: AIHealthCategory) async -> Bool {
    await AIDataSharingSettings.shared.enabledCategories.contains(category)
  }
}

// MARK: - Biological Age Diff

private extension DayReviewCalculator {

  func generateBiologicalAgeDiff(
    for date: Date,
    enabledCategories: Set<AIHealthCategory>
  ) async -> HealthVitalData.BioAgeDailyDiff? {
    // Get user's actual age
    let birthYear = await healthDefaults.getBirthYear()
    guard birthYear > 0 else { return nil }
    let currentYear = Calendar.current.component(.year, from: date)
    let actualAge = Double(currentYear - birthYear)

    // Calculate bio age for yesterday and day-before-yesterday
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: date)!
    let dayBefore = Calendar.current.date(byAdding: .day, value: -2, to: date)!

    let yesterdayResult = await BiologicalAgeCalculator.shared.calculateBiologicalAge(
      actualAge: actualAge,
      referenceDate: yesterday
    )
    let dayBeforeResult = await BiologicalAgeCalculator.shared.calculateBiologicalAge(
      actualAge: actualAge,
      referenceDate: dayBefore
    )

    // Need contributions from both days to compare
    guard !yesterdayResult.metricContributions.isEmpty,
          !dayBeforeResult.metricContributions.isEmpty else {
      return nil
    }

    // Build diff comparing contributions
    return buildDiff(
      from: dayBeforeResult,
      to: yesterdayResult,
      enabledCategories: enabledCategories
    )
  }

  func buildDiff(
    from previousResult: BiologicalAgeCalculator.CalculationResult,
    to currentResult: BiologicalAgeCalculator.CalculationResult,
    enabledCategories: Set<AIHealthCategory>
  ) -> HealthVitalData.BioAgeDailyDiff? {
    var changedMetrics = [HealthVitalData.MetricChange]()

    // Create lookup for previous contributions
    let previousContributions = Dictionary(
      uniqueKeysWithValues: previousResult.metricContributions.map { ($0.metric, $0) }
    )

    // Compare each current metric to previous
    for current in currentResult.metricContributions {
      // Check privacy filter
      guard enabledCategories.contains(privacyCategory(for: current.metric)) else { continue }

      guard let previous = previousContributions[current.metric] else { continue }

      // Calculate improvement (negative = better, positive = worse)
      let improvement = current.weightedDelta - previous.weightedDelta

      // Only include metrics that changed meaningfully (> 0.01 years)
      guard abs(improvement) > 0.01 else { continue }

      changedMetrics.append(HealthVitalData.MetricChange(
        metric: current.metric.rawValue,
        category: current.metric.category.rawValue,
        previousValue: formatMetricValue(previous),
        currentValue: formatMetricValue(current),
        previousWeightedDelta: formatWeightedDelta(previous.weightedDelta),
        currentWeightedDelta: formatWeightedDelta(current.weightedDelta),
        improvement: formatImprovement(improvement)
      ))
    }

    // Only return if there are meaningful changes
    guard changedMetrics.isNotEmpty else { return nil }

    let overallChange = currentResult.rawBiologicalAge - previousResult.rawBiologicalAge

    return HealthVitalData.BioAgeDailyDiff(
      previousBioAge: previousResult.rawBiologicalAge,
      currentBioAge: currentResult.rawBiologicalAge,
      overallChange: formatImprovement(overallChange),
      changedMetrics: changedMetrics
    )
  }

  // Privacy category mapping (same as ChatVitalConverter)
  func privacyCategory(for metric: BiologicalAgeMetric) -> AIHealthCategory {
    switch metric {
    case .vo2Max, .restingHeartRate, .heartRateRecovery, .heartRateReserve, .bodyFatPercentage:
      return .bodyMetrics
    case .hrvTrend, .bloodPressure:
      return .mentalWellness
    case .zoneMinutes, .activityLevel, .walkingSpeed, .stairClimbSpeed:
      return .physicalActivity
    case .sleepScore, .sleepDurationVariability, .bedtimeConsistency, .sleepHeartRate, .sleepRespiratoryRate:
      return .sleep
    case .smoking, .alcohol:
      return .lifestyle
    @unknown default:
      return .bodyMetrics
    }
  }

  func formatMetricValue(_ contribution: MetricContribution) -> String {
    let value = contribution.rawValue
    let formatter = NumberFormatter.oneDecimalPlace

    switch contribution.metric {
    case .vo2Max:
      return "\(formatter.string(for: value) ?? "") ml/kg/min"
    case .restingHeartRate, .heartRateRecovery, .heartRateReserve, .sleepHeartRate:
      return "\(formatter.string(for: value) ?? "") bpm"
    case .hrvTrend:
      return "\(formatter.string(for: value) ?? "")%"
    case .zoneMinutes:
      return "\(NumberFormatter.noDecimalPlaces.string(for: value) ?? "") min"
    case .activityLevel:
      return "\(formatter.string(for: value) ?? "")x"
    case .walkingSpeed, .stairClimbSpeed:
      return "\(formatter.string(for: value) ?? "") m/s"
    case .sleepScore:
      return "\(NumberFormatter.noDecimalPlaces.string(for: value) ?? "")/100"
    case .sleepDurationVariability:
      return "\(formatter.string(for: value) ?? "") hrs"
    case .bedtimeConsistency:
      return "\(NumberFormatter.noDecimalPlaces.string(for: value) ?? "") min"
    case .sleepRespiratoryRate:
      return "\(formatter.string(for: value) ?? "") breaths/min"
    case .bodyFatPercentage:
      return "\(formatter.string(for: value) ?? "")%"
    case .bloodPressure:
      return "\(NumberFormatter.noDecimalPlaces.string(for: value) ?? "") mmHg"
    case .smoking:
      return "\(formatter.string(for: value) ?? "") years since quit"
    case .alcohol:
      return "\(NumberFormatter.noDecimalPlaces.string(for: value) ?? "") drinks/week"
    @unknown default:
      return formatter.string(for: value) ?? ""
    }
  }

  func formatWeightedDelta(_ delta: Double) -> String {
    let sign = delta >= 0 ? "+" : ""
    return "\(sign)\(delta.format(using: .oneDecimalPlace)) years"
  }

  func formatImprovement(_ improvement: Double) -> String {
    let sign = improvement >= 0 ? "+" : ""
    return "\(sign)\(improvement.format(using: .oneDecimalPlace)) years"
  }
}

// MARK: - Monitor Alerts

private extension DayReviewCalculator {

  /// Fetches monitor alerts (only alert/attention states) filtered by privacy settings.
  /// A monitor's data is only included if all of its required categories are enabled.
  func fetchMonitorAlerts(enabledCategories: Set<AIHealthCategory>) async -> [MonitorContextData]? {
    // Get cached monitor results
    let results = await MonitorCalculator.shared.getCachedStates()

    // Filter to only concerning states (alert or attention)
    let concerningResults = results.filter { $0.state.isConcerning }

    guard !concerningResults.isEmpty else { return nil }

    // Filter by privacy settings - all required categories must be enabled
    let filteredResults = concerningResults.filter { result in
      let requiredCategories = requiredCategories(for: result.monitorType)
      return requiredCategories.isSubset(of: enabledCategories)
    }

    guard !filteredResults.isEmpty else { return nil }

    // Convert to context data
    return filteredResults.map { result in
      MonitorContextData(
        monitorType: result.monitorType.rawValue,
        state: result.state.rawValue,
        consecutiveDays: result.consecutiveDays,
        findings: result.findings.map { finding in
          MonitorContextData.FindingData(
            title: finding.title,
            explanation: finding.explanation
          )
        },
        stressSubtype: result.stressSubtype?.rawValue
      )
    }
  }

  /// Returns the required health categories for a monitor type.
  /// Same mapping as MonitorInsightManager.
  func requiredCategories(for monitorType: MonitorType) -> Set<AIHealthCategory> {
    switch monitorType {
    case .sleep:
      return [.sleep, .physicalActivity]
    case .recovery:
      return [.bodyMetrics, .physicalActivity]
    case .stress:
      return [.physicalActivity, .bodyMetrics, .mentalWellness]
    }
  }
}
