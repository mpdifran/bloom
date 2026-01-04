//
//  BiologicalAgeCalculator.swift
//  Bloom
//
//  Created by Mark DiFranco on 2026-01-03.
//

import Foundation
import CoreHealth
import BloomFoundation
import HealthKit
import DataContainer
import SwiftUI
import TelemetryDeck

/// Calculates biological age based on 19 health metrics
/// Runs every 4 hours with 70% previous day + 30% new blending
/// Stores one data point per calendar day (upserts same-day records)
final actor BiologicalAgeCalculator {
  static let shared = BiologicalAgeCalculator()

  @AsyncStreamable var biologicalAge: BiologicalAgeResult?

  private let healthStoreFetcher = HealthStoreFetcher.shared
  private let healthGoalProvider = HealthGoalProvider.shared
  private let healthDefaults = HealthDefaults.shared

  // Storage keys for persistence
  private static let metricContributionsKey = "BiologicalAgeCalculator.metricContributions"

  // Double-trigger mechanism: both flags must be set before we attempt calculation
  private var isInitialized = false
  private var refreshRequested = false
  private var forceRecalculateRequested = false

  private init() { }

  /// Load the latest result from SwiftData on startup
  func loadLatestResult() async {
    guard !isInitialized else {
      // Already initialized, check if we should proceed with pending refresh
      await checkAndPerformRefreshIfNeeded()
      return
    }

    let modelActor = BiologicalAgeRecordModelActor.standard()

    if let latestRecord = try? await modelActor.fetchLatest() {
      // Load metric contributions from UserDefaults
      let contributions = loadMetricContributions()

      biologicalAge = BiologicalAgeResult(
        biologicalAge: latestRecord.biologicalAge,
        actualAge: latestRecord.actualAge,
        lastCalculated: latestRecord.date,
        metricContributions: contributions
      )
    }

    isInitialized = true

    // Check if refresh was already requested while we were loading
    await checkAndPerformRefreshIfNeeded()
  }

  private func loadMetricContributions() -> [MetricContribution]? {
    guard let data = UserDefaults.standard.data(forKey: Self.metricContributionsKey) else {
      return nil
    }
    return try? JSONDecoder().decode([MetricContribution].self, from: data)
  }

  private func saveMetricContributions(_ contributions: [MetricContribution]) {
    guard let data = try? JSONEncoder().encode(contributions) else { return }
    UserDefaults.standard.set(data, forKey: Self.metricContributionsKey)
  }

  /// Refresh biological age calculation
  /// Only recalculates if 4 hours have passed since last calculation
  func refreshBiologicalAge(forceRecalculate: Bool = false) async {
    // Set the refresh request flags
    refreshRequested = true
    if forceRecalculate {
      forceRecalculateRequested = true
    }

    // Check if both conditions are met to proceed
    await checkAndPerformRefreshIfNeeded()
  }

  /// Only performs the refresh when both flags are set (initialized AND refresh requested)
  private func checkAndPerformRefreshIfNeeded() async {
    // Both flags must be set
    guard isInitialized && refreshRequested else { return }

    // Clear the refresh flag so we don't re-run
    refreshRequested = false
    let forceRecalculate = forceRecalculateRequested
    forceRecalculateRequested = false

    let userAge = getUserAge()
    guard userAge > 0 else {
      biologicalAge = nil
      return
    }

    // Check if we should recalculate (every 4 hours)
    let shouldRecalculate: Bool
    if forceRecalculate || biologicalAge == nil {
      shouldRecalculate = true
    } else {
      let hoursSince = Date().timeIntervalSince(biologicalAge!.lastCalculated) / 3600
      shouldRecalculate = hoursSince >= 4
    }

    // If we don't need to recalculate, the biologicalAge is already set from loadLatestResult
    guard shouldRecalculate else { return }

    let modelActor = BiologicalAgeRecordModelActor.standard()

    // Calculate new biological age
    let result = await calculateBiologicalAge(actualAge: Double(userAge))

    // Blend with previous day's value (70% previous day + 30% new)
    let blendedAge: Double
    if let previousDayRecord = try? await modelActor.fetchPreviousDayRecord() {
      blendedAge = (previousDayRecord.biologicalAge * 0.7) + (result.rawBiologicalAge * 0.3)
    } else {
      blendedAge = result.rawBiologicalAge
    }

    // Clamp to ±12 years from actual age
    let clampedAge = max(Double(userAge) - 12, min(Double(userAge) + 12, blendedAge))

    // Save to SwiftData (upserts same calendar day)
    try? await modelActor.upsert(
      biologicalAge: clampedAge,
      actualAge: Double(userAge),
      date: Date()
    )

    // Save metric contributions to UserDefaults
    saveMetricContributions(result.metricContributions)

    biologicalAge = BiologicalAgeResult(
      biologicalAge: clampedAge,
      actualAge: Double(userAge),
      lastCalculated: Date(),
      metricContributions: result.metricContributions
    )

    let ageDiff = clampedAge - Double(userAge)
    TelemetryDeck.signal("Bio Age Calculated", floatValue: ageDiff)
  }

  private func getUserAge() -> Int {
    let birthYear = healthDefaults.getBirthYear()
    guard birthYear > 0 else { return 0 }
    let currentYear = Calendar.current.component(.year, from: .now)
    return currentYear - birthYear
  }
}

// MARK: - Main Calculation

extension BiologicalAgeCalculator {

  public struct CalculationResult: Sendable {
    public let rawBiologicalAge: Double
    public let metricContributions: [MetricContribution]
  }

  public func calculateBiologicalAge(actualAge: Double, referenceDate: Date = .now) async -> CalculationResult {
    var totalWeightedDelta: Double = 0
    var contributions = [MetricContribution]()

    // 1. VO2 Max (18%)
    if let vo2MaxContribution = await calculateVO2MaxContribution(actualAge: actualAge, referenceDate: referenceDate) {
      totalWeightedDelta += vo2MaxContribution.weightedDelta
      contributions.append(vo2MaxContribution)
    }

    // 2. Resting Heart Rate (6%)
    if let rhrContribution = await calculateRestingHeartRateContribution(actualAge: actualAge, referenceDate: referenceDate) {
      totalWeightedDelta += rhrContribution.weightedDelta
      contributions.append(rhrContribution)
    }

    // 3. Heart Rate Recovery (6%)
    if let hrrContribution = await calculateHeartRateRecoveryContribution(actualAge: actualAge, referenceDate: referenceDate) {
      totalWeightedDelta += hrrContribution.weightedDelta
      contributions.append(hrrContribution)
    }

    // 4. HRV Trend (6%)
    if let hrvContribution = await calculateHRVTrendContribution(referenceDate: referenceDate) {
      totalWeightedDelta += hrvContribution.weightedDelta
      contributions.append(hrvContribution)
    }

    // 5. Heart Rate Reserve (4%)
    if let hrrContribution = await calculateHeartRateReserveContribution(actualAge: actualAge, referenceDate: referenceDate) {
      totalWeightedDelta += hrrContribution.weightedDelta
      contributions.append(hrrContribution)
    }

    // 6. Zone Minutes (8%)
    if let zoneMinutesContribution = await calculateZoneMinutesContribution(referenceDate: referenceDate) {
      totalWeightedDelta += zoneMinutesContribution.weightedDelta
      contributions.append(zoneMinutesContribution)
    }

    // 7. Activity Level (6%)
    if let activityContribution = await calculateActivityLevelContribution(referenceDate: referenceDate) {
      totalWeightedDelta += activityContribution.weightedDelta
      contributions.append(activityContribution)
    }

    // 8. Walking Speed (3%)
    if let walkingContribution = await calculateWalkingSpeedContribution(actualAge: actualAge, referenceDate: referenceDate) {
      totalWeightedDelta += walkingContribution.weightedDelta
      contributions.append(walkingContribution)
    }

    // 9. Stair Climb Speed (3%)
    if let stairContribution = await calculateStairClimbSpeedContribution(actualAge: actualAge, referenceDate: referenceDate) {
      totalWeightedDelta += stairContribution.weightedDelta
      contributions.append(stairContribution)
    }

    // 10. Sleep Score (8%)
    if let sleepScoreContribution = await calculateSleepScoreContribution(referenceDate: referenceDate) {
      totalWeightedDelta += sleepScoreContribution.weightedDelta
      contributions.append(sleepScoreContribution)
    }

    // 11. Sleep Duration Variability (4%)
    if let durationVarContribution = await calculateSleepDurationVariabilityContribution(referenceDate: referenceDate) {
      totalWeightedDelta += durationVarContribution.weightedDelta
      contributions.append(durationVarContribution)
    }

    // 12. Bedtime Consistency (3%)
    if let bedtimeContribution = await calculateBedtimeConsistencyContribution(referenceDate: referenceDate) {
      totalWeightedDelta += bedtimeContribution.weightedDelta
      contributions.append(bedtimeContribution)
    }

    // 13. Sleep Heart Rate (3%)
    if let sleepHRContribution = await calculateSleepHeartRateContribution(actualAge: actualAge, referenceDate: referenceDate) {
      totalWeightedDelta += sleepHRContribution.weightedDelta
      contributions.append(sleepHRContribution)
    }

    // 14. Sleep Respiratory Rate (2%)
    if let respRateContribution = await calculateSleepRespiratoryRateContribution(actualAge: actualAge, referenceDate: referenceDate) {
      totalWeightedDelta += respRateContribution.weightedDelta
      contributions.append(respRateContribution)
    }

    // 15. Body Fat Percentage (7%)
    if let bodyFatContribution = await calculateBodyFatPercentageContribution(referenceDate: referenceDate) {
      totalWeightedDelta += bodyFatContribution.weightedDelta
      contributions.append(bodyFatContribution)
    }

    // 16. Blood Pressure (8%)
    if let bpContribution = await calculateBloodPressureContribution(referenceDate: referenceDate) {
      totalWeightedDelta += bpContribution.weightedDelta
      contributions.append(bpContribution)
    }

    // 17. Macro Balance (2%)
    if let macroContribution = await calculateMacroBalanceContribution(referenceDate: referenceDate) {
      totalWeightedDelta += macroContribution.weightedDelta
      contributions.append(macroContribution)
    }

    // 18. Sugar Intake (2%)
    if let sugarContribution = await calculateSugarIntakeContribution(referenceDate: referenceDate) {
      totalWeightedDelta += sugarContribution.weightedDelta
      contributions.append(sugarContribution)
    }

    // 19. Bowel Regularity (1%)
    if let bowelContribution = await calculateBowelRegularityContribution(referenceDate: referenceDate) {
      totalWeightedDelta += bowelContribution.weightedDelta
      contributions.append(bowelContribution)
    }

    let rawBiologicalAge = actualAge + totalWeightedDelta

    return CalculationResult(
      rawBiologicalAge: rawBiologicalAge,
      metricContributions: contributions
    )
  }
}

// MARK: - Interpolation Helpers

private extension BiologicalAgeCalculator {

  /// Linear interpolation for equivalent age mappings
  /// Returns equivalent age clamped to 20-65
  func interpolateEquivalentAge(
    value: Double,
    dataPoints: [HealthGoalProvider.AgeDataPoint],
    isHigherBetter: Bool
  ) -> Double {
    guard dataPoints.count >= 2 else { return 40 }

    // Sort data points by value
    let sorted = isHigherBetter
      ? dataPoints.sorted { $0.value > $1.value }  // Higher value = younger (lower age)
      : dataPoints.sorted { $0.value < $1.value }  // Lower value = younger (lower age)

    // Find surrounding data points
    if isHigherBetter {
      // For metrics where higher is better (e.g., VO2 max, HRR)
      if value >= sorted.first!.value {
        return max(20, sorted.first!.age)
      }
      if value <= sorted.last!.value {
        return min(65, sorted.last!.age)
      }
    } else {
      // For metrics where lower is better (e.g., RHR)
      if value <= sorted.first!.value {
        return max(20, sorted.first!.age)
      }
      if value >= sorted.last!.value {
        return min(65, sorted.last!.age)
      }
    }

    // Find the two data points to interpolate between
    for i in 0..<(sorted.count - 1) {
      let lower = sorted[i]
      let upper = sorted[i + 1]

      if isHigherBetter {
        if value <= lower.value && value >= upper.value {
          let ratio = (lower.value - value) / (lower.value - upper.value)
          let interpolatedAge = lower.age + (ratio * (upper.age - lower.age))
          return max(20, min(65, interpolatedAge))
        }
      } else {
        if value >= lower.value && value <= upper.value {
          let ratio = (value - lower.value) / (upper.value - lower.value)
          let interpolatedAge = lower.age + (ratio * (upper.age - lower.age))
          return max(20, min(65, interpolatedAge))
        }
      }
    }

    return 40  // Default middle age
  }

  /// Linear interpolation for age delta mappings
  func interpolateAgeDelta(
    value: Double,
    dataPoints: [HealthGoalProvider.AgeDeltaDataPoint]
  ) -> Double {
    guard dataPoints.count >= 2 else { return 0 }

    // Sort data points by value (descending - higher value = lower delta typically)
    let sorted = dataPoints.sorted { $0.value > $1.value }

    // Clamp to bounds
    if value >= sorted.first!.value {
      return sorted.first!.ageDelta
    }
    if value <= sorted.last!.value {
      return sorted.last!.ageDelta
    }

    // Find the two data points to interpolate between
    for i in 0..<(sorted.count - 1) {
      let upper = sorted[i]
      let lower = sorted[i + 1]

      if value <= upper.value && value >= lower.value {
        let ratio = (upper.value - value) / (upper.value - lower.value)
        return upper.ageDelta + (ratio * (lower.ageDelta - upper.ageDelta))
      }
    }

    return 0
  }
}

// MARK: - Cardiorespiratory Metrics

private extension BiologicalAgeCalculator {

  // 1. VO2 Max (18%)
  func calculateVO2MaxContribution(actualAge: Double, referenceDate: Date) async -> MetricContribution? {
    let sampleType = HKQuantityType(.vo2Max)
    guard let sample = try? await healthStoreFetcher.fetchSamples(
      for: sampleType,
      dateRange: .trailingMonths(from: referenceDate, numberOfMonths: 3)
    ).first as? HKQuantitySample else { return nil }

    let vo2Max = sample.quantity.doubleValue(for: .vo2Max())
    let dataPoints = healthGoalProvider.vo2MaxAgeDataPoints()
    let equivalentAge = interpolateEquivalentAge(value: vo2Max, dataPoints: dataPoints, isHigherBetter: true)
    let ageDelta = equivalentAge - actualAge
    let weight = 0.18

    return MetricContribution(
      metric: .vo2Max,
      rawValue: vo2Max,
      equivalentAge: equivalentAge,
      ageDelta: ageDelta,
      weight: weight,
      weightedDelta: ageDelta * weight
    )
  }

  // 2. Resting Heart Rate (6%)
  func calculateRestingHeartRateContribution(actualAge: Double, referenceDate: Date) async -> MetricContribution? {
    guard let avgRHR = await healthStoreFetcher.fetchDailyAverage(
      for: .restingHeartRate,
      unit: .bpm(),
      dateRange: .trailingDays(from: referenceDate, numberOfDays: 7)
    )?.doubleValue(for: .bpm()) else { return nil }

    let dataPoints = healthGoalProvider.restingHeartRateAgeDataPoints()
    let equivalentAge = interpolateEquivalentAge(value: avgRHR, dataPoints: dataPoints, isHigherBetter: false)
    let ageDelta = equivalentAge - actualAge
    let weight = 0.06

    return MetricContribution(
      metric: .restingHeartRate,
      rawValue: avgRHR,
      equivalentAge: equivalentAge,
      ageDelta: ageDelta,
      weight: weight,
      weightedDelta: ageDelta * weight
    )
  }

  // 3. Heart Rate Recovery (6%)
  func calculateHeartRateRecoveryContribution(actualAge: Double, referenceDate: Date) async -> MetricContribution? {
    let sampleType = HKQuantityType(.heartRateRecoveryOneMinute)
    guard let sample = try? await healthStoreFetcher.fetchSamples(
      for: sampleType,
      dateRange: .trailingDays(from: referenceDate, numberOfDays: 30)
    ).first as? HKQuantitySample else { return nil }

    let hrr = sample.quantity.doubleValue(for: .bpm())
    let dataPoints = healthGoalProvider.heartRateRecoveryAgeDataPoints()
    let equivalentAge = interpolateEquivalentAge(value: hrr, dataPoints: dataPoints, isHigherBetter: true)
    let ageDelta = equivalentAge - actualAge
    let weight = 0.06

    return MetricContribution(
      metric: .heartRateRecovery,
      rawValue: hrr,
      equivalentAge: equivalentAge,
      ageDelta: ageDelta,
      weight: weight,
      weightedDelta: ageDelta * weight
    )
  }

  // 4. HRV Trend (6%)
  func calculateHRVTrendContribution(referenceDate: Date) async -> MetricContribution? {
    let sampleType = HKQuantityType(.heartRateVariabilitySDNN)
    let unit = HKUnit.secondUnit(with: .milli)

    guard let sevenDaySamples = try? await healthStoreFetcher.fetchSamples(
      for: sampleType,
      dateRange: .trailingDays(from: referenceDate, numberOfDays: 7)
    ) as? [HKQuantitySample],
    sevenDaySamples.isNotEmpty else { return nil }

    guard let thirtyDaySamples = try? await healthStoreFetcher.fetchSamples(
      for: sampleType,
      dateRange: .trailingDays(from: referenceDate, numberOfDays: 30)
    ) as? [HKQuantitySample],
    thirtyDaySamples.isNotEmpty else { return nil }

    let sevenDayAvg = sevenDaySamples.map { $0.quantity.doubleValue(for: unit) }.reduce(0, +) / Double(sevenDaySamples.count)
    let thirtyDayAvg = thirtyDaySamples.map { $0.quantity.doubleValue(for: unit) }.reduce(0, +) / Double(thirtyDaySamples.count)

    guard thirtyDayAvg > 0 else { return nil }

    let percentChange = ((sevenDayAvg - thirtyDayAvg) / thirtyDayAvg) * 100
    let dataPoints = healthGoalProvider.hrvTrendAgeDeltaDataPoints()
    let ageDelta = interpolateAgeDelta(value: percentChange, dataPoints: dataPoints)
    let weight = 0.06

    return MetricContribution(
      metric: .hrvTrend,
      rawValue: percentChange,
      equivalentAge: nil,
      ageDelta: ageDelta,
      weight: weight,
      weightedDelta: ageDelta * weight
    )
  }

  // 5. Heart Rate Reserve (4%)
  func calculateHeartRateReserveContribution(actualAge: Double, referenceDate: Date) async -> MetricContribution? {
    // Get max HR from last 7 days
    let maxHRSamples = await healthStoreFetcher.fetchCollatedQuantity(
      for: .heartRate,
      unit: .bpm(),
      interval: DateComponents(day: 1),
      options: .discreteMax,
      dateRange: .trailingDays(from: referenceDate, numberOfDays: 7)
    )

    // Get average resting HR from last 7 days
    guard let avgRHR = await healthStoreFetcher.fetchDailyAverage(
      for: .restingHeartRate,
      unit: .bpm(),
      dateRange: .trailingDays(from: referenceDate, numberOfDays: 7)
    )?.doubleValue(for: .bpm()) else { return nil }

    guard maxHRSamples.isNotEmpty else { return nil }

    let highestMaxHR = maxHRSamples.map { $0.quantity.doubleValue(for: .bpm()) }.max() ?? 0
    guard highestMaxHR > 0 else { return nil }

    let hrr = highestMaxHR - avgRHR
    guard hrr > 0 else { return nil }

    let dataPoints = healthGoalProvider.heartRateReserveAgeDataPoints()
    let equivalentAge = interpolateEquivalentAge(value: hrr, dataPoints: dataPoints, isHigherBetter: true)
    let ageDelta = equivalentAge - actualAge
    let weight = 0.04

    return MetricContribution(
      metric: .heartRateReserve,
      rawValue: hrr,
      equivalentAge: equivalentAge,
      ageDelta: ageDelta,
      weight: weight,
      weightedDelta: ageDelta * weight
    )
  }
}

// MARK: - Activity Metrics

private extension BiologicalAgeCalculator {

  // 6. Zone Minutes (8%)
  func calculateZoneMinutesContribution(referenceDate: Date) async -> MetricContribution? {
    guard let heartRateZones = await healthStoreFetcher.heartRateZones() else { return nil }

    let details = await healthStoreFetcher.fetchExerciseEffectivenessDetails(
      heartRateZones: heartRateZones,
      dateRange: .trailingDays(from: referenceDate, numberOfDays: 7)
    )

    guard !details.workoutReports.isEmpty else { return nil }

    let totalZoneMinutes = details.workoutReports.reduce(0.0) { sum, report in
      sum + report.heartZoneDistribution.scaledDurationSum.doubleValue(for: .minute())
    }

    let dataPoints = healthGoalProvider.zoneMinutesAgeDeltaDataPoints()
    let ageDelta = interpolateAgeDelta(value: totalZoneMinutes, dataPoints: dataPoints)
    let weight = 0.08

    return MetricContribution(
      metric: .zoneMinutes,
      rawValue: totalZoneMinutes,
      equivalentAge: nil,
      ageDelta: ageDelta,
      weight: weight,
      weightedDelta: ageDelta * weight
    )
  }

  // 7. Activity Level (6%)
  func calculateActivityLevelContribution(referenceDate: Date) async -> MetricContribution? {
    // Fetch active and basal energy for 7 days
    let activeEnergy = await healthStoreFetcher.fetchCollatedQuantity(
      for: .activeEnergyBurned,
      unit: .kilocalorie(),
      interval: DateComponents(day: 1),
      dateRange: .trailingDays(from: referenceDate, numberOfDays: 7)
    )

    let basalEnergy = await healthStoreFetcher.fetchCollatedQuantity(
      for: .basalEnergyBurned,
      unit: .kilocalorie(),
      interval: DateComponents(day: 1),
      dateRange: .trailingDays(from: referenceDate, numberOfDays: 7)
    )

    guard activeEnergy.isNotEmpty, basalEnergy.isNotEmpty else { return nil }

    let totalActive = activeEnergy.map { $0.quantity.doubleValue(for: .kilocalorie()) }.reduce(0, +)
    let totalBasal = basalEnergy.map { $0.quantity.doubleValue(for: .kilocalorie()) }.reduce(0, +)

    guard totalBasal > 0 else { return nil }

    let ratio = (totalActive + totalBasal) / totalBasal
    let dataPoints = healthGoalProvider.activityLevelAgeDeltaDataPoints()
    let ageDelta = interpolateAgeDelta(value: ratio, dataPoints: dataPoints)
    let weight = 0.06

    return MetricContribution(
      metric: .activityLevel,
      rawValue: ratio,
      equivalentAge: nil,
      ageDelta: ageDelta,
      weight: weight,
      weightedDelta: ageDelta * weight
    )
  }

  // 8. Walking Speed (3%)
  func calculateWalkingSpeedContribution(actualAge: Double, referenceDate: Date) async -> MetricContribution? {
    guard let avgWalkingSpeed = await healthStoreFetcher.fetchDailyAverage(
      for: .walkingSpeed,
      unit: .meter().unitDivided(by: .second()),
      dateRange: .trailingDays(from: referenceDate, numberOfDays: 7)
    )?.doubleValue(for: .meter().unitDivided(by: .second())) else { return nil }

    let dataPoints = healthGoalProvider.walkingSpeedAgeDataPoints()
    let equivalentAge = interpolateEquivalentAge(value: avgWalkingSpeed, dataPoints: dataPoints, isHigherBetter: true)
    let ageDelta = equivalentAge - actualAge
    let weight = 0.03

    return MetricContribution(
      metric: .walkingSpeed,
      rawValue: avgWalkingSpeed,
      equivalentAge: equivalentAge,
      ageDelta: ageDelta,
      weight: weight,
      weightedDelta: ageDelta * weight
    )
  }

  // 9. Stair Climb Speed (3%)
  func calculateStairClimbSpeedContribution(actualAge: Double, referenceDate: Date) async -> MetricContribution? {
    let unit = HKUnit.meter().unitDivided(by: .second())
    guard let avgStairSpeed = await healthStoreFetcher.fetchDailyAverage(
      for: .stairAscentSpeed,
      unit: unit,
      dateRange: .trailingDays(from: referenceDate, numberOfDays: 7)
    )?.doubleValue(for: unit) else { return nil }

    let dataPoints = healthGoalProvider.stairClimbSpeedAgeDataPoints()
    let equivalentAge = interpolateEquivalentAge(value: avgStairSpeed, dataPoints: dataPoints, isHigherBetter: true)
    let ageDelta = equivalentAge - actualAge
    let weight = 0.03

    return MetricContribution(
      metric: .stairClimbSpeed,
      rawValue: avgStairSpeed,
      equivalentAge: equivalentAge,
      ageDelta: ageDelta,
      weight: weight,
      weightedDelta: ageDelta * weight
    )
  }
}

// MARK: - Sleep Metrics

private extension BiologicalAgeCalculator {

  // 10. Sleep Score (8%)
  func calculateSleepScoreContribution(referenceDate: Date) async -> MetricContribution? {
    let sleepAnalyses = await healthStoreFetcher.fetchSleepAnalysis(
      dateRange: .trailingDays(from: referenceDate, numberOfDays: 7)
    )

    guard sleepAnalyses.isNotEmpty else { return nil }

    let avgScore = sleepAnalyses.map(\.overallScoreDouble).reduce(0, +) / Double(sleepAnalyses.count)
    let dataPoints = healthGoalProvider.sleepScoreAgeDeltaDataPoints()
    let ageDelta = interpolateAgeDelta(value: avgScore, dataPoints: dataPoints)
    let weight = 0.08

    return MetricContribution(
      metric: .sleepScore,
      rawValue: avgScore,
      equivalentAge: nil,
      ageDelta: ageDelta,
      weight: weight,
      weightedDelta: ageDelta * weight
    )
  }

  // 11. Sleep Duration Variability (4%)
  func calculateSleepDurationVariabilityContribution(referenceDate: Date) async -> MetricContribution? {
    let sleepAnalyses = await healthStoreFetcher.fetchSleepAnalysis(
      dateRange: .trailingDays(from: referenceDate, numberOfDays: 7)
    )

    guard sleepAnalyses.count >= 3 else { return nil }

    // Calculate standard deviation of sleep duration in hours
    let durations = sleepAnalyses.map { $0.overallMinutes / 60.0 }
    let mean = durations.reduce(0, +) / Double(durations.count)
    let variance = durations.map { pow($0 - mean, 2) }.reduce(0, +) / Double(durations.count)
    let stdDev = sqrt(variance)

    let dataPoints = healthGoalProvider.sleepDurationVariabilityAgeDeltaDataPoints()
    let ageDelta = interpolateAgeDelta(value: stdDev, dataPoints: dataPoints)
    let weight = 0.04

    return MetricContribution(
      metric: .sleepDurationVariability,
      rawValue: stdDev,
      equivalentAge: nil,
      ageDelta: ageDelta,
      weight: weight,
      weightedDelta: ageDelta * weight
    )
  }

  // 12. Bedtime Consistency (3%)
  func calculateBedtimeConsistencyContribution(referenceDate: Date) async -> MetricContribution? {
    let sleepAnalyses = await healthStoreFetcher.fetchSleepAnalysis(
      dateRange: .trailingDays(from: referenceDate, numberOfDays: 7)
    )

    guard sleepAnalyses.count >= 3 else { return nil }

    // Calculate bedtime in minutes from midnight, handling times after midnight
    let bedtimeMinutes = sleepAnalyses.map { analysis -> Double in
      let calendar = Calendar.current
      let components = calendar.dateComponents([.hour, .minute], from: analysis.startDate)
      var minutes = Double(components.hour ?? 0) * 60 + Double(components.minute ?? 0)
      // If before noon, treat as after midnight (add 24 hours)
      if minutes < 12 * 60 {
        minutes += 24 * 60
      }
      return minutes
    }

    let mean = bedtimeMinutes.reduce(0, +) / Double(bedtimeMinutes.count)
    let variance = bedtimeMinutes.map { pow($0 - mean, 2) }.reduce(0, +) / Double(bedtimeMinutes.count)
    let stdDev = sqrt(variance)

    let dataPoints = healthGoalProvider.bedtimeConsistencyAgeDeltaDataPoints()
    let ageDelta = interpolateAgeDelta(value: stdDev, dataPoints: dataPoints)
    let weight = 0.03

    return MetricContribution(
      metric: .bedtimeConsistency,
      rawValue: stdDev,
      equivalentAge: nil,
      ageDelta: ageDelta,
      weight: weight,
      weightedDelta: ageDelta * weight
    )
  }

  // 13. Sleep Heart Rate (3%)
  func calculateSleepHeartRateContribution(actualAge: Double, referenceDate: Date) async -> MetricContribution? {
    let sleepAnalyses = await healthStoreFetcher.fetchSleepAnalysis(
      dateRange: .trailingDays(from: referenceDate, numberOfDays: 7)
    )

    let heartRates = sleepAnalyses.compactMap(\.averageHeartRate)
    guard heartRates.isNotEmpty else { return nil }

    let avgSleepHR = heartRates.reduce(0, +) / Double(heartRates.count)
    let dataPoints = healthGoalProvider.sleepHeartRateAgeDataPoints()
    let equivalentAge = interpolateEquivalentAge(value: avgSleepHR, dataPoints: dataPoints, isHigherBetter: false)
    let ageDelta = equivalentAge - actualAge
    let weight = 0.03

    return MetricContribution(
      metric: .sleepHeartRate,
      rawValue: avgSleepHR,
      equivalentAge: equivalentAge,
      ageDelta: ageDelta,
      weight: weight,
      weightedDelta: ageDelta * weight
    )
  }

  // 14. Sleep Respiratory Rate (2%)
  func calculateSleepRespiratoryRateContribution(actualAge: Double, referenceDate: Date) async -> MetricContribution? {
    let sleepAnalyses = await healthStoreFetcher.fetchSleepAnalysis(
      dateRange: .trailingDays(from: referenceDate, numberOfDays: 7)
    )

    let respiratoryRates: [Double] = sleepAnalyses.flatMap { analysis in
      analysis.respiratoryRate.map(\.averageRespiratoryRate)
    }

    guard respiratoryRates.isNotEmpty else { return nil }

    let avgRespRate = respiratoryRates.reduce(0, +) / Double(respiratoryRates.count)
    let dataPoints = healthGoalProvider.sleepRespiratoryRateAgeDataPoints()
    let equivalentAge = interpolateEquivalentAge(value: avgRespRate, dataPoints: dataPoints, isHigherBetter: false)
    let ageDelta = equivalentAge - actualAge
    let weight = 0.02

    return MetricContribution(
      metric: .sleepRespiratoryRate,
      rawValue: avgRespRate,
      equivalentAge: equivalentAge,
      ageDelta: ageDelta,
      weight: weight,
      weightedDelta: ageDelta * weight
    )
  }
}

// MARK: - Body Composition Metrics

private extension BiologicalAgeCalculator {

  // 15. Body Fat Percentage (7%)
  func calculateBodyFatPercentageContribution(referenceDate: Date) async -> MetricContribution? {
    // Body fat is measured infrequently, look back 90 days from reference date
    let sample = await healthStoreFetcher.fetchMostRecentSample(
      for: .bodyFatPercentage,
      dateRange: .trailingDays(from: referenceDate, numberOfDays: 90)
    )
    guard let sample else { return nil }

    let bodyFatPercent = sample.quantity.doubleValue(for: .percent())
    let dataPoints = healthGoalProvider.bodyFatPercentageAgeDeltaDataPoints()
    let ageDelta = interpolateAgeDelta(value: bodyFatPercent, dataPoints: dataPoints)
    let weight = 0.07

    return MetricContribution(
      metric: .bodyFatPercentage,
      rawValue: bodyFatPercent,
      equivalentAge: nil,
      ageDelta: ageDelta,
      weight: weight,
      weightedDelta: ageDelta * weight
    )
  }

  // 16. Blood Pressure (8%)
  func calculateBloodPressureContribution(referenceDate: Date) async -> MetricContribution? {
    // Blood pressure is measured infrequently, look back 30 days from reference date
    let dateRange = DateRange.trailingDays(from: referenceDate, numberOfDays: 30)
    guard let systolicSample = await healthStoreFetcher.fetchMostRecentSample(for: .bloodPressureSystolic, dateRange: dateRange),
          let diastolicSample = await healthStoreFetcher.fetchMostRecentSample(for: .bloodPressureDiastolic, dateRange: dateRange)
    else { return nil }

    let systolic = systolicSample.quantity.doubleValue(for: .millimeterOfMercury())
    let diastolic = diastolicSample.quantity.doubleValue(for: .millimeterOfMercury())

    let category = healthGoalProvider.bloodPressureCategory(systolic: systolic, diastolic: diastolic)
    let ageDelta = healthGoalProvider.bloodPressureAgeDelta(for: category)
    let weight = 0.08

    return MetricContribution(
      metric: .bloodPressure,
      rawValue: systolic,  // Store systolic as the raw value for display
      equivalentAge: nil,
      ageDelta: ageDelta,
      weight: weight,
      weightedDelta: ageDelta * weight
    )
  }
}

// MARK: - Nutrition Metrics

private extension BiologicalAgeCalculator {

  // 17. Macro Balance (2%)
  func calculateMacroBalanceContribution(referenceDate: Date) async -> MetricContribution? {
    let dateRange = DateRange.trailingDays(from: referenceDate, numberOfDays: 7)

    // Fetch total calories and macros
    let energySamples = await healthStoreFetcher.fetchCollatedQuantity(
      for: .dietaryEnergyConsumed,
      unit: .kilocalorie(),
      interval: DateComponents(day: 1),
      dateRange: dateRange
    )

    let proteinSamples = await healthStoreFetcher.fetchCollatedQuantity(
      for: .dietaryProtein,
      unit: .gram(),
      interval: DateComponents(day: 1),
      dateRange: dateRange
    )

    let carbSamples = await healthStoreFetcher.fetchCollatedQuantity(
      for: .dietaryCarbohydrates,
      unit: .gram(),
      interval: DateComponents(day: 1),
      dateRange: dateRange
    )

    let fatSamples = await healthStoreFetcher.fetchCollatedQuantity(
      for: .dietaryFatTotal,
      unit: .gram(),
      interval: DateComponents(day: 1),
      dateRange: dateRange
    )

    guard energySamples.isNotEmpty else { return nil }

    let totalEnergy = energySamples.map { $0.quantity.doubleValue(for: .kilocalorie()) }.reduce(0, +)
    let totalProtein = proteinSamples.map { $0.quantity.doubleValue(for: .gram()) }.reduce(0, +)
    let totalCarbs = carbSamples.map { $0.quantity.doubleValue(for: .gram()) }.reduce(0, +)
    let totalFat = fatSamples.map { $0.quantity.doubleValue(for: .gram()) }.reduce(0, +)

    guard totalEnergy > 0 else { return nil }

    // Calculate percentages (protein: 4 cal/g, carbs: 4 cal/g, fat: 9 cal/g)
    let proteinPercent = (totalProtein * 4) / totalEnergy
    let carbPercent = (totalCarbs * 4) / totalEnergy
    let fatPercent = (totalFat * 9) / totalEnergy

    // Check how many macros are in range
    let carbRange = healthGoalProvider.recommendedDailyCarbohydratesPercentOfDietaryEnergy()
    let fatRange = healthGoalProvider.recommendedDailyFatPercentOfDietaryEnergy()
    let proteinRange = healthGoalProvider.recommendedDailyProteinPercentOfDietaryEnergy()

    var macrosInRange = 0
    if carbRange.contains(carbPercent) { macrosInRange += 1 }
    if fatRange.contains(fatPercent) { macrosInRange += 1 }
    if proteinRange.contains(proteinPercent) { macrosInRange += 1 }

    let ageDelta = healthGoalProvider.macroBalanceAgeDelta(macrosInRange: macrosInRange)
    let weight = 0.02

    return MetricContribution(
      metric: .macroBalance,
      rawValue: Double(macrosInRange),
      equivalentAge: nil,
      ageDelta: ageDelta,
      weight: weight,
      weightedDelta: ageDelta * weight
    )
  }

  // 18. Sugar Intake (2%)
  func calculateSugarIntakeContribution(referenceDate: Date) async -> MetricContribution? {
    let sugarSamples = await healthStoreFetcher.fetchCollatedQuantity(
      for: .dietarySugar,
      unit: .gram(),
      interval: DateComponents(day: 1),
      dateRange: .trailingDays(from: referenceDate, numberOfDays: 7)
    )

    guard sugarSamples.isNotEmpty else { return nil }

    let avgDailySugar = sugarSamples.map { $0.quantity.doubleValue(for: .gram()) }.reduce(0, +) / Double(sugarSamples.count)
    let recommendedMax = healthGoalProvider.recommendedMaxDailyIntakeForSugar().doubleValue(for: .gram())

    guard recommendedMax > 0 else { return nil }

    let percentOfLimit = (avgDailySugar / recommendedMax) * 100
    let dataPoints = healthGoalProvider.sugarIntakeAgeDeltaDataPoints()
    let ageDelta = interpolateAgeDelta(value: percentOfLimit, dataPoints: dataPoints)
    let weight = 0.02

    return MetricContribution(
      metric: .sugarIntake,
      rawValue: percentOfLimit,
      equivalentAge: nil,
      ageDelta: ageDelta,
      weight: weight,
      weightedDelta: ageDelta * weight
    )
  }

  // 19. Bowel Regularity (1%)
  func calculateBowelRegularityContribution(referenceDate: Date) async -> MetricContribution? {
    let modelActor = BowelMovementModelActor.standard()
    guard let bowelMovements = try? await modelActor.fetchBowelMovements(dateRange: .trailingDays(from: referenceDate, numberOfDays: 7)),
          bowelMovements.isNotEmpty else { return nil }

    // Use existing scoring logic
    let summary = BowelMovementMonthlySummary(bowelMovements: bowelMovements)
    let score = summary.score

    let ageDelta = healthGoalProvider.bowelRegularityAgeDelta(score: score)
    let weight = 0.01

    return MetricContribution(
      metric: .bowelRegularity,
      rawValue: score,
      equivalentAge: nil,
      ageDelta: ageDelta,
      weight: weight,
      weightedDelta: ageDelta * weight
    )
  }
}

// MARK: - Supporting Types

public enum BiologicalAgeConfidence: String, Sendable, Codable {
  case high
  case moderate
  case low

  public var displayName: String {
    switch self {
    case .high: "High Confidence"
    case .moderate: "Moderate Confidence"
    case .low: "Low Confidence"
    }
  }

  public var description: String {
    switch self {
    case .high:
      "Your biological age is calculated using most of your available health metrics."
    case .moderate:
      "Your biological age is based on a moderate amount of health data. Adding more metrics will improve accuracy."
    case .low:
      "Limited health data is available. Track more health metrics to get a more accurate biological age."
    }
  }

  public var color: Color {
    switch self {
    case .high: .mutedGreen
    case .moderate: .mutedYellow
    case .low: .secondary
    }
  }
}

public struct BiologicalAgeResult: Sendable {
  public let biologicalAge: Double
  public let actualAge: Double
  public let lastCalculated: Date
  public var metricContributions: [MetricContribution]?

  public var ageDelta: Double {
    biologicalAge - actualAge
  }

  public var isYounger: Bool {
    biologicalAge < actualAge
  }

  /// The percentage of available health metrics by weight (0-100)
  public var availableWeightPercentage: Double {
    let totalWeight = metricContributions?.reduce(0.0) { $0 + $1.weight } ?? 0
    return totalWeight * 100
  }

  /// The confidence level based on available metric weight coverage
  public var confidence: BiologicalAgeConfidence {
    let percentage = availableWeightPercentage
    if percentage > 80 { return .high }
    if percentage > 50 { return .moderate }
    return .low
  }
}

public struct MetricContribution: Sendable, Identifiable, Codable {
  public var id: BiologicalAgeMetric { metric }
  public let metric: BiologicalAgeMetric
  public let rawValue: Double
  public let equivalentAge: Double?
  public let ageDelta: Double
  public let weight: Double
  public let weightedDelta: Double
}

public enum BiologicalAgeMetric: String, Sendable, CaseIterable, Codable {
  case vo2Max = "VO2 Max"
  case restingHeartRate = "Resting Heart Rate"
  case heartRateRecovery = "Heart Rate Recovery"
  case hrvTrend = "HRV Trend"
  case heartRateReserve = "Heart Rate Reserve"
  case zoneMinutes = "Zone Minutes"
  case activityLevel = "Activity Level"
  case walkingSpeed = "Walking Speed"
  case stairClimbSpeed = "Stair Climb Speed"
  case sleepScore = "Sleep Score"
  case sleepDurationVariability = "Sleep Variability"
  case bedtimeConsistency = "Bedtime Consistency"
  case sleepHeartRate = "Sleep Heart Rate"
  case sleepRespiratoryRate = "Respiratory Rate"
  case bodyFatPercentage = "Body Fat %"
  case bloodPressure = "Blood Pressure"
  case macroBalance = "Macro Balance"
  case sugarIntake = "Sugar Intake"
  case bowelRegularity = "Bowel Regularity"

  public var weight: Double {
    switch self {
    case .vo2Max: 0.18
    case .restingHeartRate: 0.06
    case .heartRateRecovery: 0.06
    case .hrvTrend: 0.06
    case .heartRateReserve: 0.04
    case .zoneMinutes: 0.08
    case .activityLevel: 0.06
    case .walkingSpeed: 0.03
    case .stairClimbSpeed: 0.03
    case .sleepScore: 0.08
    case .sleepDurationVariability: 0.04
    case .bedtimeConsistency: 0.03
    case .sleepHeartRate: 0.03
    case .sleepRespiratoryRate: 0.02
    case .bodyFatPercentage: 0.07
    case .bloodPressure: 0.08
    case .macroBalance: 0.02
    case .sugarIntake: 0.02
    case .bowelRegularity: 0.01
    }
  }

  public var category: BiologicalAgeCategory {
    switch self {
    case .vo2Max, .restingHeartRate, .heartRateRecovery, .hrvTrend, .heartRateReserve:
      return .cardiorespiratory
    case .zoneMinutes, .activityLevel, .walkingSpeed, .stairClimbSpeed:
      return .activity
    case .sleepScore, .sleepDurationVariability, .bedtimeConsistency, .sleepHeartRate, .sleepRespiratoryRate:
      return .sleep
    case .bodyFatPercentage, .bloodPressure:
      return .bodyComposition
    case .macroBalance, .sugarIntake, .bowelRegularity:
      return .nutrition
    }
  }
}

public enum BiologicalAgeCategory: String, Sendable, CaseIterable {
  case cardiorespiratory = "Cardiorespiratory"
  case activity = "Activity"
  case sleep = "Sleep"
  case bodyComposition = "Body Composition"
  case nutrition = "Nutrition"
}
