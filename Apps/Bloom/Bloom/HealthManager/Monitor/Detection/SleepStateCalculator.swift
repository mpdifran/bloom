//
//  SleepStateCalculator.swift
//  Bloom
//
//  Created by Claude on 2026-01-09.
//

import Foundation
import DataContainer

/// Calculates state for the Sleep Quality & Rhythm Monitor.
/// Tracks sleep patterns and circadian rhythm disruptions.
actor SleepStateCalculator: MonitorStateCalculator {

  let monitorType: MonitorType = .sleep

  let requiredMetrics: [MonitorMetricType] = [.sleepDuration]
  let optionalMetrics: [MonitorMetricType] = [.sleepEfficiency, .bedtime, .wakeTime]

  func calculateState(
    for date: Date,
    samples: [DailyMetricSampleDTO],
    previousResults: [MonitorResult]
  ) async -> MonitorResult {
    // Check required metrics using lookback window (today + yesterday)
    // Sleep data may be attributed to yesterday if session started before midnight
    guard let durationSample = mostRecentSample(for: .sleepDuration, in: samples, targetDate: date) else {
      return .unavailable(
        monitorType: .sleep,
        reason: "We couldn't find sleep data for this date.",
        requiredMetrics: requiredMetrics
      )
    }

    // Get optional sleep metrics using the same lookback window
    let efficiencySample = mostRecentSample(for: .sleepEfficiency, in: samples, targetDate: date)
    let bedtimeSample = mostRecentSample(for: .bedtime, in: samples, targetDate: date)
    let wakeTimeSample = mostRecentSample(for: .wakeTime, in: samples, targetDate: date)

    // For confidence calculation, check which metrics are present in recent window
    let presentMetrics = Set(
      [durationSample, efficiencySample, bedtimeSample, wakeTimeSample]
        .compactMap { $0?.metricType }
    )

    var signals: [Signal] = []

    // Sleep duration signals
    if let zScore = durationSample.zScore {
      let baseline = durationSample.baseline7Day ?? durationSample.baseline28Day
      let difference = baseline.map { durationSample.value - $0 }
      if zScore < -2.0 {
        signals.append(Signal(
          metricType: .sleepDuration,
          date: date,
          zScore: zScore,
          direction: .lower,
          description: "Your Sleep Duration Is Very Low",
          difference: difference
        ))
      } else if zScore < -1.0 {
        signals.append(Signal(
          metricType: .sleepDuration,
          date: date,
          zScore: zScore,
          direction: .lower,
          description: "You've Been Getting Less Sleep Than Your Usual",
          difference: difference
        ))
      }
    }

    // Sleep efficiency signals (optional)
    if let efficiencySample {
      let efficiency = efficiencySample.value / 100 // Convert from percentage
      let baseline = efficiencySample.baseline7Day ?? efficiencySample.baseline28Day
      let difference = baseline.map { efficiencySample.value - $0 } // Difference in percentage points
      if efficiency < 0.75 {
        signals.append(Signal(
          metricType: .sleepEfficiency,
          date: date,
          zScore: (0.85 - efficiency) * 10, // Approximate z-score
          direction: .lower,
          description: "Sleep Efficiency Is Low — You May Be Waking Frequently",
          difference: difference
        ))
      } else if efficiency < 0.85 {
        signals.append(Signal(
          metricType: .sleepEfficiency,
          date: date,
          zScore: (0.85 - efficiency) * 10,
          direction: .lower,
          description: "Sleep Efficiency Is Below Optimal",
          difference: difference
        ))
      }
    }

    // Bedtime/wake variability signals (optional)
    // Note: calculateScheduleVariability already looks at 7 days of data
    let variability = calculateScheduleVariability(samples: samples, date: date)
    if let variabilityMinutes = variability {
      if variabilityMinutes > 90 {
        signals.append(Signal(
          metricType: .bedtime,
          date: date,
          zScore: variabilityMinutes / 30, // Approximate z-score
          direction: .variable,
          description: "Your Sleep Schedule Has Been Highly Variable",
          difference: variabilityMinutes
        ))
      } else if variabilityMinutes > 60 {
        signals.append(Signal(
          metricType: .bedtime,
          date: date,
          zScore: variabilityMinutes / 30,
          direction: .variable,
          description: "Your Bedtime Has Been Inconsistent",
          difference: variabilityMinutes
        ))
      }
    }

    // Wake time variability signals (optional)
    let wakeVariability = calculateWakeTimeVariability(samples: samples, date: date)
    if let variabilityMinutes = wakeVariability {
      if variabilityMinutes > 90 {
        signals.append(Signal(
          metricType: .wakeTime,
          date: date,
          zScore: variabilityMinutes / 30,
          direction: .variable,
          description: "Your Wake Time Has Been Highly Variable",
          difference: variabilityMinutes
        ))
      } else if variabilityMinutes > 60 {
        signals.append(Signal(
          metricType: .wakeTime,
          date: date,
          zScore: variabilityMinutes / 30,
          direction: .variable,
          description: "Your Wake Time Has Been Inconsistent",
          difference: variabilityMinutes
        ))
      }
    }

    // Determine state
    let rawState = determineState(signals: signals, variability: variability)

    // Calculate confidence
    let confidence = calculateConfidence(
      requiredPresent: true,
      optionalMetrics: optionalMetrics,
      presentMetrics: presentMetrics
    )

    // Check persistence (3 days for Off state per PRD)
    let consecutiveDays = countConsecutiveDays(
      state: rawState,
      previousResults: previousResults,
      currentDate: date
    )

    let finalState: MonitorStateValue
    if rawState == .alert && consecutiveDays < 3 {
      finalState = .attention
    } else if rawState == .attention && consecutiveDays < 2 {
      finalState = .good
    } else {
      finalState = rawState
    }

    // Generate findings
    let findings = generateFindings(signals: signals, state: finalState, variability: variability)

    return MonitorResult(
      monitorType: .sleep,
      state: finalState,
      confidence: confidence,
      consecutiveDays: consecutiveDays,
      signals: signals,
      findings: findings
    )
  }

  // MARK: - Private Methods

  private func calculateScheduleVariability(samples: [DailyMetricSampleDTO], date: Date) -> Double? {
    let calendar = Calendar.current
    let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: date)!

    let bedtimeSamples = samples.filter {
      $0.metricType == MonitorMetricType.bedtime.rawValue && $0.date >= sevenDaysAgo
    }

    guard bedtimeSamples.count >= 3 else { return nil }

    let values = bedtimeSamples.map { $0.value }
    let mean = values.reduce(0, +) / Double(values.count)
    let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
    let stdDev = sqrt(variance)

    return stdDev // Standard deviation in minutes
  }

  private func calculateWakeTimeVariability(samples: [DailyMetricSampleDTO], date: Date) -> Double? {
    let calendar = Calendar.current
    let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: date)!

    let wakeTimeSamples = samples.filter {
      $0.metricType == MonitorMetricType.wakeTime.rawValue && $0.date >= sevenDaysAgo
    }

    guard wakeTimeSamples.count >= 3 else { return nil }

    let values = wakeTimeSamples.map { $0.value }
    let mean = values.reduce(0, +) / Double(values.count)
    let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
    let stdDev = sqrt(variance)

    return stdDev // Standard deviation in minutes
  }

  private func determineState(signals: [Signal], variability: Double?) -> MonitorStateValue {
    // Alert: Duration very low OR efficiency < 0.75 OR variability > 90min
    let hasVeryLowDuration = signals.contains {
      $0.metricType == .sleepDuration && $0.magnitude > 2.0
    }
    let hasLowEfficiency = signals.contains {
      $0.metricType == .sleepEfficiency && $0.magnitude > 1.0
    }

    if hasVeryLowDuration || hasLowEfficiency || (variability ?? 0) > 90 {
      return .alert
    }

    // Attention: Duration declining OR efficiency 0.75-0.85 OR variability 60-90min
    let hasDecliningDuration = signals.contains {
      $0.metricType == .sleepDuration && $0.magnitude > 1.0
    }
    let hasModerateEfficiency = signals.contains {
      $0.metricType == .sleepEfficiency && $0.magnitude > 0.5
    }

    if hasDecliningDuration || hasModerateEfficiency || (variability ?? 0) > 60 {
      return .attention
    }

    return .good
  }

  private func generateFindings(signals: [Signal], state: MonitorStateValue, variability: Double?) -> [Finding] {
    guard state != .good else { return [] }

    var findings: [Finding] = []

    // Duration finding
    if let durationSignal = signals.first(where: { $0.metricType == .sleepDuration }) {
      let severity = durationSignal.severity == .high ? "significantly" : "somewhat"

      findings.append(Finding(
        title: durationSignal.description,
        explanation: "Your sleep duration has been \(severity) below your usual for the past few days. Try to prioritize getting to bed earlier.",
        confidence: state == .alert ? .high : .medium,
        relatedMetrics: [.sleepDuration]
      ))
    }

    // Efficiency finding
    if let efficiencySignal = signals.first(where: { $0.metricType == .sleepEfficiency }) {
      findings.append(Finding(
        title: efficiencySignal.description,
        explanation: "You may be spending more time awake in bed than usual. Consider limiting screen time before bed and keeping a consistent sleep schedule.",
        confidence: .medium,
        relatedMetrics: [.sleepEfficiency]
      ))
    }

    // Variability finding
    if let variabilityMinutes = variability, variabilityMinutes > 60 {
      let variabilityDescription = variabilityMinutes > 90 ? "Highly Variable" : "Inconsistent"

      findings.append(Finding(
        title: "Your Sleep Schedule Has Been \(variabilityDescription)",
        explanation: "Your bedtime has varied by about \(Int(variabilityMinutes)) minutes over the past week. A more consistent schedule can improve sleep quality.",
        confidence: variabilityMinutes > 90 ? .high : .medium,
        relatedMetrics: [.bedtime, .wakeTime]
      ))
    }

    return findings
  }
}
