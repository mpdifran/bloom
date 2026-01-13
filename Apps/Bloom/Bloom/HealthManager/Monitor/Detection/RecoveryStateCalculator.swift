//
//  RecoveryStateCalculator.swift
//  Bloom
//
//  Created by Claude on 2026-01-09.
//

import Foundation
import DataContainer

/// Calculates state for the Recovery & Sickness Monitor.
/// Detects early physiological signs that suggest the body is fighting something.
actor RecoveryStateCalculator: MonitorStateCalculator {

  let monitorType: MonitorType = .recovery

  let requiredMetrics: [MonitorMetricType] = [.restingHeartRate, .heartRateVariability]
  let optionalMetrics: [MonitorMetricType] = [.wristTemperature, .respiratoryRate]

  func calculateState(
    for date: Date,
    samples: [DailyMetricSampleDTO],
    previousResults: [MonitorResult]
  ) async -> MonitorResult {
    let calendar = Calendar.current

    // Extract today's samples
    let todaySamples = samples.filter { calendar.isDate($0.date, inSameDayAs: date) }
    let presentMetrics = Set(todaySamples.map { $0.metricType })

    // Check required metric availability
    let hasRHR = presentMetrics.contains(MonitorMetricType.restingHeartRate.rawValue)
    let hasHRV = presentMetrics.contains(MonitorMetricType.heartRateVariability.rawValue)

    guard hasRHR && hasHRV else {
      return .unavailable(
        monitorType: .recovery,
        reason: "We need both resting heart rate and HRV data to assess recovery.",
        requiredMetrics: requiredMetrics
      )
    }

    // Collect signals from each metric
    var signals: [Signal] = []

    // RHR: Higher = concerning (positive z-score is bad)
    if let rhrSample = todaySamples.first(where: { $0.metricType == MonitorMetricType.restingHeartRate.rawValue }),
       let zScore = rhrSample.zScore, zScore > 1.0 {
      let baseline = rhrSample.baseline28Day ?? rhrSample.baseline7Day
      let difference = baseline.map { rhrSample.value - $0 }
      signals.append(Signal(
        metricType: .restingHeartRate,
        date: date,
        zScore: zScore,
        direction: .higher,
        description: "Your resting heart rate is higher than usual",
        difference: difference
      ))
    }

    // HRV: Lower = concerning (negative z-score is bad)
    if let hrvSample = todaySamples.first(where: { $0.metricType == MonitorMetricType.heartRateVariability.rawValue }),
       let zScore = hrvSample.zScore, zScore < -1.0 {
      let baseline = hrvSample.baseline28Day ?? hrvSample.baseline7Day
      let difference = baseline.map { hrvSample.value - $0 }
      signals.append(Signal(
        metricType: .heartRateVariability,
        date: date,
        zScore: zScore,
        direction: .lower,
        description: "Your heart rate variability is lower than usual",
        difference: difference
      ))
    }

    // Wrist Temperature: Higher = concerning (optional)
    if let tempSample = todaySamples.first(where: { $0.metricType == MonitorMetricType.wristTemperature.rawValue }),
       let zScore = tempSample.zScore, zScore > 1.0 {
      let baseline = tempSample.baseline28Day ?? tempSample.baseline7Day
      let difference = baseline.map { tempSample.value - $0 }
      signals.append(Signal(
        metricType: .wristTemperature,
        date: date,
        zScore: zScore,
        direction: .higher,
        description: "Elevated wrist temperature during sleep",
        difference: difference
      ))
    }

    // Respiratory Rate: Higher = concerning (optional)
    if let respSample = todaySamples.first(where: { $0.metricType == MonitorMetricType.respiratoryRate.rawValue }),
       let zScore = respSample.zScore, zScore > 1.0 {
      let baseline = respSample.baseline28Day ?? respSample.baseline7Day
      let difference = baseline.map { respSample.value - $0 }
      signals.append(Signal(
        metricType: .respiratoryRate,
        date: date,
        zScore: zScore,
        direction: .higher,
        description: "Your respiratory rate is higher than usual",
        difference: difference
      ))
    }

    // Determine raw state based on signals
    let rawState = determineState(signals: signals)

    // Calculate confidence based on optional data availability
    let confidence = calculateConfidence(
      requiredPresent: true,
      optionalMetrics: optionalMetrics,
      presentMetrics: presentMetrics
    )

    // Determine final state with persistence bypass for strong signals
    let finalState: MonitorStateValue
    let consecutiveDays: Int

    if shouldBypassPersistence(signals: signals, rawState: rawState) {
      // Strong multi-signal cases bypass the 2-day persistence rule
      // This prevents the catch-22 where Day 1 suppression blocks Day 2 detection
      finalState = rawState
      consecutiveDays = 1
    } else if rawState == .good {
      finalState = .good
      consecutiveDays = countConsecutiveDays(
        state: rawState,
        previousResults: previousResults,
        currentDate: date
      )
    } else {
      // Apply persistence rule for moderate signals
      consecutiveDays = countConsecutiveDays(
        state: rawState,
        previousResults: previousResults,
        currentDate: date
      )
      if consecutiveDays >= 2 {
        finalState = rawState
      } else {
        // Haven't hit 2-day threshold yet, show as good
        finalState = .good
      }
    }

    // Generate findings
    let findings = generateFindings(signals: signals, state: finalState, confidence: confidence)

    return MonitorResult(
      monitorType: .recovery,
      state: finalState,
      confidence: confidence,
      consecutiveDays: consecutiveDays,
      signals: signals,
      findings: findings
    )
  }

  // MARK: - Private Methods

  /// Determines if the persistence rule should be bypassed for strong signal cases.
  /// This prevents the catch-22 where Day 1 signals get suppressed, preventing Day 2 from counting.
  private func shouldBypassPersistence(signals: [Signal], rawState: MonitorStateValue) -> Bool {
    guard rawState != .good else { return false }

    let highSeveritySignals = signals.filter { $0.severity == .high }

    // Bypass 1: 2+ high-severity signals (z-score > 2.0)
    // Statistically significant - chance of random occurrence is very low
    if highSeveritySignals.count >= 2 {
      return true
    }

    // Bypass 2: Elevated wrist temp (strong sickness indicator) + any other elevated signal
    // Wrist temperature elevation is a particularly strong indicator of illness
    let hasHighTemp = signals.contains { $0.metricType == .wristTemperature && $0.severity == .high }
    let hasOtherElevated = signals.contains { $0.metricType != .wristTemperature && $0.severity >= .elevated }

    if hasHighTemp && hasOtherElevated {
      return true
    }

    return false
  }

  private func determineState(signals: [Signal]) -> MonitorStateValue {
    // Alert: 2+ signals > 2.0 z-score
    let highSeveritySignals = signals.filter { $0.severity == .high }
    if highSeveritySignals.count >= 2 {
      return .alert
    }

    // High-confidence pattern: RHR elevated + HRV depressed + (temp or resp elevated)
    let hasElevatedRHR = signals.contains { $0.metricType == .restingHeartRate && $0.severity >= .elevated }
    let hasDepressedHRV = signals.contains { $0.metricType == .heartRateVariability && $0.severity >= .elevated }
    let hasElevatedTemp = signals.contains { $0.metricType == .wristTemperature && $0.severity >= .elevated }
    let hasElevatedResp = signals.contains { $0.metricType == .respiratoryRate && $0.severity >= .elevated }

    if hasElevatedRHR && hasDepressedHRV && (hasElevatedTemp || hasElevatedResp) {
      return .alert
    }

    // Attention: 1+ signals at 1.0-2.0 z-score
    let elevatedSignals = signals.filter { $0.severity >= .elevated }
    if !elevatedSignals.isEmpty {
      return .attention
    }

    return .good
  }

  private func generateFindings(signals: [Signal], state: MonitorStateValue, confidence: Double) -> [Finding] {
    guard state != .good else { return [] }

    var findings: [Finding] = []

    // Group signals by severity for explanation
    let elevatedSignals = signals.filter { $0.severity >= .elevated }

    if elevatedSignals.count >= 2 {
      // Multiple corroborating signals
      let metrics = elevatedSignals.map { $0.metricType }
      let descriptions = elevatedSignals.map { $0.description }.joined(separator: ". ")

      findings.append(Finding(
        title: state == .alert ? "Your body may be fighting something" : "Some recovery metrics are off",
        explanation: "\(descriptions). This pattern has been present for multiple days. Consider taking it easy and getting extra rest.",
        confidence: .high,
        relatedMetrics: metrics
      ))
    } else if let signal = elevatedSignals.first {
      // Single signal
      let findingConfidence: FindingConfidence = confidence > 0.7 ? .medium : .low

      findings.append(Finding(
        title: signal.description,
        explanation: "This has been the case for a couple of days. It could be normal variation, or a sign your body needs more rest.",
        confidence: findingConfidence,
        relatedMetrics: [signal.metricType]
      ))
    }

    return findings
  }
}
