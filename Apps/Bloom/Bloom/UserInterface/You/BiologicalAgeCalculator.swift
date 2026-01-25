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
  private static let lastResultKey = "BiologicalAgeCalculator.lastResult"

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

      let loadedResult = BiologicalAgeResult(
        biologicalAge: latestRecord.biologicalAge,
        actualAge: latestRecord.actualAge,
        lastCalculated: latestRecord.date,
        metricContributions: contributions
      )
      biologicalAge = loadedResult

      // Save full result for watch app access (ensures watch has latest data)
      saveLastResult(loadedResult)
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

  private func saveLastResult(_ result: BiologicalAgeResult) {
    guard let data = try? JSONEncoder().encode(result) else { return }
    UserDefaults.standard.set(data, forKey: Self.lastResultKey)
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

    internalLog(.biologicalAge, "Starting calculation")

    let modelActor = BiologicalAgeRecordModelActor.standard()

    // Calculate new biological age
    let result = await calculateBiologicalAge(actualAge: userAge)

    // Blend with previous day's value (70% previous day + 30% new)
    let blendedAge: Double
    if let previousDayRecord = try? await modelActor.fetchPreviousDayRecord() {
      blendedAge = (previousDayRecord.biologicalAge * 0.7) + (result.rawBiologicalAge * 0.3)
    } else {
      blendedAge = result.rawBiologicalAge
    }

    // Clamp to ±12 years from actual age
    let clampedAge = max(userAge - 12, min(userAge + 12, blendedAge))

    // Save to SwiftData (upserts same calendar day)
    try? await modelActor.upsert(
      biologicalAge: clampedAge,
      actualAge: userAge,
      date: Date()
    )

    // Save metric contributions to UserDefaults
    saveMetricContributions(result.metricContributions)

    let newResult = BiologicalAgeResult(
      biologicalAge: clampedAge,
      actualAge: userAge,
      lastCalculated: Date(),
      metricContributions: result.metricContributions
    )
    biologicalAge = newResult

    // Save full result for watch app access
    saveLastResult(newResult)

    internalLog(.biologicalAge, "Calculated: \(String(format: "%.1f", clampedAge)) (actual: \(String(format: "%.1f", userAge)))")

    let ageDiff = clampedAge - userAge
    TelemetryDeck.signal("Bio Age Calculated", floatValue: ageDiff)
  }

  private func getUserAge() -> Double {
    let birthYear = healthDefaults.getBirthYear()
    guard birthYear > 0 else { return 0 }
    let birthMonth = healthDefaults.getBirthMonth()
    let now = Date.now
    let calendar = Calendar.current
    let currentYear = calendar.component(.year, from: now)
    let currentMonth = calendar.component(.month, from: now)
    let currentDay = calendar.component(.day, from: now)

    var years = Double(currentYear - birthYear)

    if birthMonth > 0 {
      // Calculate fractional age using mid-month (15th) as birthday
      let monthsSinceBirthday: Int
      if currentMonth > birthMonth || (currentMonth == birthMonth && currentDay >= 15) {
        // Birthday has passed this year
        monthsSinceBirthday = currentMonth - birthMonth + (currentDay >= 15 ? 0 : -1)
      } else {
        // Birthday hasn't passed yet
        years -= 1
        monthsSinceBirthday = 12 - birthMonth + currentMonth + (currentDay >= 15 ? 0 : -1)
      }
      return years + (Double(max(0, monthsSinceBirthday)) / 12.0)
    } else {
      // No birth month - use day of year for fraction (Jan 1 baseline)
      let dayOfYear = calendar.ordinality(of: .day, in: .year, for: now) ?? 1
      let daysInYear = calendar.range(of: .day, in: .year, for: now)?.count ?? 365
      return years + (Double(dayOfYear - 1) / Double(daysInYear))
    }
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

    // 17. Smoking (7%)
    if let smokingContribution = await calculateSmokingContribution() {
      totalWeightedDelta += smokingContribution.weightedDelta
      contributions.append(smokingContribution)
    }

    // 18. Alcohol (3%)
    if let alcoholContribution = await calculateAlcoholContribution(referenceDate: referenceDate) {
      totalWeightedDelta += alcoholContribution.weightedDelta
      contributions.append(alcoholContribution)
    }

    let rawBiologicalAge = actualAge + totalWeightedDelta

    return CalculationResult(
      rawBiologicalAge: rawBiologicalAge,
      metricContributions: contributions
    )
  }

  /// Calculates the bio age delta from workout-affected metrics only.
  /// This is an optimized calculation that only recalculates Zone Minutes and Activity Level,
  /// comparing against stored previous values.
  /// Returns the delta in years (negative = younger).
  public func calculateWorkoutBioAgeDelta() async -> Double? {
    // Load stored metric contributions
    guard let storedContributions = loadMetricContributions() else { return nil }

    // Get previous values for workout-affected metrics
    let previousZoneMinutes = storedContributions.first { $0.metric == .zoneMinutes }?.weightedDelta ?? 0
    let previousActivityLevel = storedContributions.first { $0.metric == .activityLevel }?.weightedDelta ?? 0

    // Recalculate with current data (which includes the new workout)
    let newZoneMinutes = await calculateZoneMinutesContribution(referenceDate: .now)?.weightedDelta ?? 0
    let newActivityLevel = await calculateActivityLevelContribution(referenceDate: .now)?.weightedDelta ?? 0

    // Calculate the delta
    let zoneMinutesDelta = newZoneMinutes - previousZoneMinutes
    let activityLevelDelta = newActivityLevel - previousActivityLevel

    let totalDelta = zoneMinutesDelta + activityLevelDelta

    // Return nil if no significant change (less than ~1 hour = 0.000114 years)
    guard abs(totalDelta) > 0.0001 else { return nil }

    return totalDelta
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

// MARK: - Lifestyle Metrics

private extension BiologicalAgeCalculator {

  // 17. Smoking (7%)
  func calculateSmokingContribution() async -> MetricContribution? {
    let status = healthDefaults.getSmokingStatus()
    guard status != .unknown else { return nil }

    let ageDelta: Double
    let rawValue: Double

    switch status {
    case .current:
      ageDelta = 8.0
      rawValue = 1.0
    case .former:
      if let quitDate = healthDefaults.getSmokingQuitDate() {
        let yearsSinceQuit = Date().timeIntervalSince(quitDate) / (365.25 * 24 * 3600)
        ageDelta = 6.0 * exp(-yearsSinceQuit / 6.0)
        rawValue = yearsSinceQuit
      } else {
        // Assume mid-recovery if quit date not set
        ageDelta = 3.0
        rawValue = 3.0
      }
    case .never:
      ageDelta = 0.0
      rawValue = 0.0
    case .unknown:
      return nil
    }

    let weight = 0.07

    return MetricContribution(
      metric: .smoking,
      rawValue: rawValue,
      equivalentAge: nil,
      ageDelta: ageDelta,
      weight: weight,
      weightedDelta: ageDelta * weight
    )
  }

  // 18. Alcohol (3%)
  func calculateAlcoholContribution(referenceDate: Date) async -> MetricContribution? {
    let samples = await healthStoreFetcher.fetchCollatedQuantity(
      for: .numberOfAlcoholicBeverages,
      unit: .count(),
      interval: DateComponents(day: 1),
      dateRange: .trailingDays(from: referenceDate, numberOfDays: 7)
    )
    guard samples.isNotEmpty else { return nil }

    let sex = healthDefaults.getSexKind()
    let bingeThreshold = (sex == .male) ? 5.0 : 4.0
    let heavyThreshold = (sex == .male) ? 10.0 : 8.0

    let dailyDrinks = samples.map { $0.quantity.doubleValue(for: .count()) }
    let weeklyTotal = dailyDrinks.reduce(0, +)
    let bingeDays = dailyDrinks.filter { $0 >= bingeThreshold }.count
    let heavyDays = dailyDrinks.filter { $0 >= heavyThreshold }.count

    // Risk score (0-1)
    let bingeComponent = min(1.0, Double(bingeDays) / 2.0)
    let heavyComponent = min(1.0, Double(heavyDays) / 1.0) * 0.5
    let totalComponent = weeklyTotal > 7 ? min(1.0, (weeklyTotal - 7) / 14) * 0.5 : 0.0

    let risk = min(1.0, max(0.0, 0.6 * bingeComponent + 0.2 * heavyComponent + 0.2 * totalComponent))
    let ageDelta = 6.0 * risk  // 0 to +6 years

    let weight = 0.03

    return MetricContribution(
      metric: .alcohol,
      rawValue: weeklyTotal,
      equivalentAge: nil,
      ageDelta: ageDelta,
      weight: weight,
      weightedDelta: ageDelta * weight
    )
  }
}

// Types moved to CoreHealth/Model/BiologicalAgeTypes.swift:
// - BiologicalAgeConfidence
// - BiologicalAgeResult
// - MetricContribution
// - BiologicalAgeMetric
// - BiologicalAgeCategory
