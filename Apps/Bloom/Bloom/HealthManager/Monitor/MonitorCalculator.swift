//
//  MonitorCalculator.swift
//  Bloom
//
//  Created by Claude on 2026-01-09.
//

import Foundation
import HealthKit
import CoreHealth
import DataContainer
import BloomFoundation

/// Actor responsible for fetching health metrics from HealthKit,
/// calculating baselines and z-scores, and persisting DailyMetricSamples.
actor MonitorCalculator {

  static let shared = MonitorCalculator()

  private let healthStoreFetcher = HealthStoreFetcher.shared

  private init() { }

  // MARK: - Public API

  /// Fetches and calculates all metrics for a specific date.
  /// Call this on app launch and periodically to keep data fresh.
  func calculateMetricsForDate(_ date: Date) async throws {
    let normalizedDate = Calendar.current.startOfDay(for: date)

    // Fetch all metrics in parallel
    async let rhrResult = fetchRestingHeartRate(for: normalizedDate)
    async let hrvResult = fetchHeartRateVariability(for: normalizedDate)
    async let wristTempResult = fetchWristTemperature(for: normalizedDate)
    async let respiratoryResult = fetchRespiratoryRate(for: normalizedDate)
    async let sleepResult = fetchSleepMetrics(for: normalizedDate)

    // Collect results
    var samples: [DailyMetricSampleInput] = []

    if let rhr = await rhrResult {
      samples.append(rhr)
    }
    if let hrv = await hrvResult {
      samples.append(hrv)
    }
    if let wristTemp = await wristTempResult {
      samples.append(wristTemp)
    }
    if let respiratory = await respiratoryResult {
      samples.append(respiratory)
    }

    // Sleep returns multiple metrics
    let sleepMetrics = await sleepResult
    samples.append(contentsOf: sleepMetrics)

    // Now calculate baselines and z-scores for each sample
    let samplesWithBaselines = try await calculateBaselinesAndZScores(for: samples, date: normalizedDate)

    // Persist to SwiftData
    let modelActor = DailyMetricSampleModelActor.standard()
    try await modelActor.upsertBatch(samplesWithBaselines)
  }

  /// Fetches metrics for the past N days from today (for backfilling recent data)
  func backfillMetrics(days: Int) async throws {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())

    for dayOffset in 0..<days {
      guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
      try await calculateMetricsForDate(date)
    }
  }

  /// Fetches metrics for a specific date range (for historical analysis)
  /// - Parameters:
  ///   - startDate: First date to backfill (inclusive)
  ///   - endDate: Last date to backfill (inclusive)
  func backfillMetrics(from startDate: Date, to endDate: Date) async throws {
    let calendar = Calendar.current
    var currentDate = calendar.startOfDay(for: startDate)
    let normalizedEndDate = calendar.startOfDay(for: endDate)

    while currentDate <= normalizedEndDate {
      try await calculateMetricsForDate(currentDate)
      guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
      currentDate = nextDate
    }
  }

  // MARK: - Metric Fetchers

  private func fetchRestingHeartRate(for date: Date) async -> DailyMetricSampleInput? {
    let dateRange = DateRange.duringDay(date)
    // Resting heart rate is a discrete type, so use fetchCollatedAverage
    let samples = await healthStoreFetcher.fetchCollatedAverage(
      quantityType: .restingHeartRate,
      unit: .bpm(),
      dateRange: dateRange
    )

    guard let sample = samples.first else { return nil }

    let quality = determineQuality(sampleCount: samples.count, expected: 1)

    return DailyMetricSampleInput(
      date: date,
      metricType: MonitorMetricType.restingHeartRate.rawValue,
      value: sample.quantity.doubleValue(for: .bpm()),
      quality: quality
    )
  }

  private func fetchHeartRateVariability(for date: Date) async -> DailyMetricSampleInput? {
    let dateRange = DateRange.duringDay(date)
    let samples = await healthStoreFetcher.fetchCollatedAverage(
      quantityType: .heartRateVariabilitySDNN,
      unit: .secondUnit(with: .milli),
      dateRange: dateRange
    )

    guard let sample = samples.first else { return nil }

    let quality = determineQuality(sampleCount: samples.count, expected: 1)

    return DailyMetricSampleInput(
      date: date,
      metricType: MonitorMetricType.heartRateVariability.rawValue,
      value: sample.quantity.doubleValue(for: .secondUnit(with: .milli)),
      quality: quality
    )
  }

  private func fetchWristTemperature(for date: Date) async -> DailyMetricSampleInput? {
    let dateRange = DateRange.duringDay(date)
    let samples = await healthStoreFetcher.fetchCollatedAverage(
      quantityType: .appleSleepingWristTemperature,
      unit: .degreeFahrenheit(),
      dateRange: dateRange
    )

    guard let sample = samples.first else { return nil }

    let quality = determineQuality(sampleCount: samples.count, expected: 1)

    return DailyMetricSampleInput(
      date: date,
      metricType: MonitorMetricType.wristTemperature.rawValue,
      value: sample.quantity.doubleValue(for: .degreeFahrenheit()),
      quality: quality
    )
  }

  private func fetchRespiratoryRate(for date: Date) async -> DailyMetricSampleInput? {
    // Respiratory rate is also collected during sleep
    guard let sleepAnalysis = await healthStoreFetcher.fetchSleepAnalysis(for: date) else { return nil }

    let avgRespiratoryRate = sleepAnalysis.respiratoryRate.average(keyPath: \.averageRespiratoryRate)
    guard avgRespiratoryRate > 0 else { return nil }

    return DailyMetricSampleInput(
      date: date,
      metricType: MonitorMetricType.respiratoryRate.rawValue,
      value: avgRespiratoryRate
    )
  }

  private func fetchSleepMetrics(for date: Date) async -> [DailyMetricSampleInput] {
    var results: [DailyMetricSampleInput] = []

    // Sleep data for "today" is actually last night's sleep ending today
    guard let sleep = await healthStoreFetcher.fetchSleepAnalysis(for: date) else { return results }

    // Sleep Duration
    results.append(DailyMetricSampleInput(
      date: date,
      metricType: MonitorMetricType.sleepDuration.rawValue,
      value: sleep.overallMinutes
    ))

    // Deep Sleep (if available)
    if sleep.hasDetailedSleepCategories && sleep.deepSleepMinutes > 0 {
      results.append(DailyMetricSampleInput(
        date: date,
        metricType: MonitorMetricType.deepSleep.rawValue,
        value: sleep.deepSleepMinutes
      ))
    }

    // REM Sleep (if available)
    if sleep.hasDetailedSleepCategories && sleep.remSleepMinutes > 0 {
      results.append(DailyMetricSampleInput(
        date: date,
        metricType: MonitorMetricType.remSleep.rawValue,
        value: sleep.remSleepMinutes
      ))
    }

    // Sleep Efficiency
    if sleep.overallMinutesIncludingAwake > 0 {
      let efficiency = (sleep.overallMinutes / sleep.overallMinutesIncludingAwake) * 100
      results.append(DailyMetricSampleInput(
        date: date,
        metricType: MonitorMetricType.sleepEfficiency.rawValue,
        value: efficiency
      ))
    }

    // Bedtime (minutes from midnight, adjusted for overnight)
    // Use the actual date from sleep.startDate (typically the previous evening)
    let bedtimeMinutes = minutesFromMidnight(sleep.startDate)
    let bedtimeDate = Calendar.current.startOfDay(for: sleep.startDate)
    results.append(DailyMetricSampleInput(
      date: bedtimeDate,
      metricType: MonitorMetricType.bedtime.rawValue,
      value: bedtimeMinutes
    ))

    // Wake Time (minutes from midnight)
    // Use the actual date from sleep.endDate
    let wakeMinutes = minutesFromMidnight(sleep.endDate)
    let wakeDate = Calendar.current.startOfDay(for: sleep.endDate)
    results.append(DailyMetricSampleInput(
      date: wakeDate,
      metricType: MonitorMetricType.wakeTime.rawValue,
      value: wakeMinutes
    ))

    return results
  }

  // MARK: - Baseline & Z-Score Calculation

  private func calculateBaselinesAndZScores(
    for samples: [DailyMetricSampleInput],
    date: Date
  ) async throws -> [DailyMetricSampleInput] {
    let modelActor = DailyMetricSampleModelActor.standard()

    var results: [DailyMetricSampleInput] = []

    for sample in samples {
      guard let metricType = MonitorMetricType(rawValue: sample.metricType) else {
        results.append(sample)
        continue
      }

      // Fetch historical data for baseline calculation
      let baselineDays = max(metricType.primaryBaselineDays, 28)
      guard let startDate = Calendar.current.date(byAdding: .day, value: -baselineDays, to: date) else {
        results.append(sample)
        continue
      }

      let historicalRange = DateRange(startDate, date)
      let historicalSamples = try await modelActor.fetchSamples(
        metricType: sample.metricType,
        dateRange: historicalRange
      )

      // Calculate baselines
      let baseline7Day = calculateBaseline(samples: historicalSamples, days: 7, beforeDate: date)
      let baseline28Day = metricType.uses28DayBaseline
        ? calculateBaseline(samples: historicalSamples, days: 28, beforeDate: date)
        : nil

      // Calculate z-score using primary baseline
      let zScore = calculateZScore(
        value: sample.value,
        samples: historicalSamples,
        baselineDays: metricType.primaryBaselineDays,
        beforeDate: date
      )

      results.append(DailyMetricSampleInput(
        date: sample.date,
        metricType: sample.metricType,
        value: sample.value,
        quality: sample.quality,
        baseline7Day: baseline7Day,
        baseline28Day: baseline28Day,
        zScore: zScore
      ))
    }

    return results
  }

  /// Calculates the rolling average baseline for a given number of days
  private func calculateBaseline(
    samples: [DailyMetricSampleDTO],
    days: Int,
    beforeDate: Date
  ) -> Double? {
    let calendar = Calendar.current
    guard let cutoffDate = calendar.date(byAdding: .day, value: -days, to: beforeDate) else {
      return nil
    }

    let relevantSamples = samples.filter { sample in
      sample.date >= cutoffDate && sample.date < beforeDate
    }

    guard !relevantSamples.isEmpty else { return nil }

    let sum = relevantSamples.reduce(0.0) { $0 + $1.value }
    return sum / Double(relevantSamples.count)
  }

  /// Calculates z-score: (value - mean) / standardDeviation
  private func calculateZScore(
    value: Double,
    samples: [DailyMetricSampleDTO],
    baselineDays: Int,
    beforeDate: Date
  ) -> Double? {
    let calendar = Calendar.current
    guard let cutoffDate = calendar.date(byAdding: .day, value: -baselineDays, to: beforeDate) else {
      return nil
    }

    let relevantSamples = samples.filter { sample in
      sample.date >= cutoffDate && sample.date < beforeDate
    }

    // Need at least 3 samples for meaningful z-score
    guard relevantSamples.count >= 3 else { return nil }

    let values = relevantSamples.map { $0.value }
    let mean = values.reduce(0, +) / Double(values.count)

    let squaredDiffs = values.map { pow($0 - mean, 2) }
    let variance = squaredDiffs.reduce(0, +) / Double(values.count)
    let standardDeviation = sqrt(variance)

    // Avoid division by zero
    guard standardDeviation > 0 else { return nil }

    return (value - mean) / standardDeviation
  }

  // MARK: - Helpers

  private func determineQuality(sampleCount: Int, expected: Int) -> String {
    if sampleCount >= expected {
      return "complete"
    } else if sampleCount > 0 {
      return "partial"
    } else {
      return "sparse"
    }
  }

  private func minutesFromMidnight(_ date: Date) -> Double {
    let calendar = Calendar.current
    let components = calendar.dateComponents([.hour, .minute], from: date)
    let hours = Double(components.hour ?? 0)
    let minutes = Double(components.minute ?? 0)

    var totalMinutes = hours * 60 + minutes

    // For bedtime, if it's before noon, add 24 hours (it's "tomorrow" relative to sleep start)
    if totalMinutes < 12 * 60 {
      totalMinutes += 24 * 60
    }

    return totalMinutes
  }
}

// MARK: - Detection Engine Integration

extension MonitorCalculator {

  /// Calculates metrics for the date and then runs the detection engine.
  /// This is the main entry point for the Monitor feature.
  /// - Parameter date: The date to calculate for (defaults to today)
  /// - Returns: Array of MonitorResult for each monitor type
  func calculateMetricsAndDetect(for date: Date = Date()) async throws -> [MonitorResult] {
    // Phase 1: Fetch metrics and persist
    try await calculateMetricsForDate(date)

    // Phase 2: Run detection engine
    return try await DetectionEngine.shared.calculateAllStates(for: date)
  }

  /// Returns the current monitor states without recalculating metrics.
  /// Use this when you just need to display states and don't need fresh HealthKit data.
  func getCurrentStates() async throws -> [MonitorResult] {
    try await DetectionEngine.shared.calculateAllStates()
  }

  /// Returns cached monitor states without any calculation.
  /// Returns empty if no states have been calculated yet.
  func getCachedStates() async -> [MonitorResult] {
    await DetectionEngine.shared.getAllCachedResults()
  }

  /// Returns the overall status across all monitors.
  func getOverallStatus() async throws -> MonitorStateValue {
    try await DetectionEngine.shared.overallStatus()
  }

  /// Returns monitors that need attention (Watch or Off state).
  func getMonitorsNeedingAttention() async throws -> [MonitorResult] {
    try await DetectionEngine.shared.monitorsNeedingAttention()
  }

  /// Backfills metrics and loads historical detection results.
  /// Call this on first launch or when significant historical data is needed.
  func backfillMetricsAndDetection(days: Int) async throws {
    // First backfill the metrics (Phase 1)
    try await backfillMetrics(days: days)

    // Then load historical detection results (Phase 2)
    try await DetectionEngine.shared.loadHistoricalResults(days: min(days, 7))
  }
}
