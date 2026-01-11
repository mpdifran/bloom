//
//  StressStateCalculator.swift
//  Bloom
//
//  Created by Claude on 2026-01-09.
//

import Foundation
import DataContainer

/// Calculates state for the Stress & Workout Load Monitor.
/// Tracks training load balance and detects overtraining.
actor StressStateCalculator: MonitorStateCalculator {

  let monitorType: MonitorType = .stress

  let requiredMetrics: [MonitorMetricType] = [.activeEnergy]
  let optionalMetrics: [MonitorMetricType] = [.heartRateVariability, .heartRateRecovery]

  // MARK: - Activity History Classification

  /// Classification of user's historical activity patterns
  private enum ActivityHistoryClassification: Sendable {
    /// User has never been consistently active
    case beginner
    /// User was active before but not recently
    case returning
    /// User is currently active, no encouragement needed
    case active
  }

  /// Thresholds for activity classification
  private enum ActivityThresholds {
    /// Daily average below this is considered low activity (kcal)
    static let lowActivityDailyAverage: Double = 150
    /// Peak 4-week average above this indicates user was previously active (kcal)
    static let peakActivityThreshold: Double = 300
    /// How far back to look for historical patterns (days)
    static let historicalLookbackDays: Int = 180
    /// Minimum days needed for meaningful classification
    static let minimumDaysForClassification: Int = 30
    /// Window size for rolling peak average calculation
    static let peakWindowDays: Int = 28
  }

  func calculateState(
    for date: Date,
    samples: [DailyMetricSampleDTO],
    previousResults: [MonitorResult]
  ) async -> MonitorResult {
    let calendar = Calendar.current

    // Get active energy samples for ratio calculation
    let energySamples = samples
      .filter { $0.metricType == MonitorMetricType.activeEnergy.rawValue }
      .sorted { $0.date < $1.date }

    // Need at least 7 days of data for meaningful ratio
    // When insufficient data, always show encourage state (never unavailable)
    guard energySamples.count >= 7 else {
      let classification = classifyActivityHistory(samples: samples, date: date)
      return createEncourageResult(classification: classification, date: date)
    }

    // Calculate Acute:Chronic Ratio
    let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: date)!
    let twentyEightDaysAgo = calendar.date(byAdding: .day, value: -28, to: date)!

    let acuteSamples = energySamples.filter { $0.date >= sevenDaysAgo && $0.date < date }
    let chronicSamples = energySamples.filter { $0.date >= twentyEightDaysAgo && $0.date < date }

    let acuteLoad = acuteSamples.reduce(0.0) { $0 + $1.value }
    let chronicDailyAvg = chronicSamples.isEmpty ? 0 : chronicSamples.reduce(0.0) { $0 + $1.value } / Double(chronicSamples.count)
    let chronicWeeklyEquivalent = chronicDailyAvg * 7

    let acuteChronicRatio: Double = chronicWeeklyEquivalent > 0 ? acuteLoad / chronicWeeklyEquivalent : 1.0

    // Collect signals
    var signals: [Signal] = []

    // Ratio signals
    if acuteChronicRatio > 1.5 {
      signals.append(Signal(
        metricType: .activeEnergy,
        date: date,
        zScore: (acuteChronicRatio - 1.0) * 2, // Approximate z-score
        direction: .higher,
        description: "Your training load has spiked significantly"
      ))
    } else if acuteChronicRatio > 1.3 {
      signals.append(Signal(
        metricType: .activeEnergy,
        date: date,
        zScore: (acuteChronicRatio - 1.0) * 2,
        direction: .higher,
        description: "Your training load is above optimal range"
      ))
    } else if acuteChronicRatio < 0.8 {
      signals.append(Signal(
        metricType: .activeEnergy,
        date: date,
        zScore: (0.8 - acuteChronicRatio) * 2,
        direction: .lower,
        description: "Your training load is below your usual"
      ))
    }

    // HRV trend check (optional) - compare recent 7-day to baseline
    let hrvDecline = calculateHRVTrendDecline(samples: samples, date: date)
    if let decline = hrvDecline {
      if decline > 0.15 { // >15% decline
        signals.append(Signal(
          metricType: .heartRateVariability,
          date: date,
          zScore: decline * 10, // Convert to approximate z-score
          direction: .lower,
          description: "Your HRV has declined significantly over recent days"
        ))
      } else if decline > 0.05 { // 5-15% decline
        signals.append(Signal(
          metricType: .heartRateVariability,
          date: date,
          zScore: decline * 10,
          direction: .lower,
          description: "Your HRV is trending downward"
        ))
      }
    }

    // Determine state
    let rawState = determineState(
      signals: signals,
      acuteChronicRatio: acuteChronicRatio,
      hrvDecline: hrvDecline
    )

    // Calculate confidence
    let presentMetrics = Set(samples.filter { calendar.isDate($0.date, inSameDayAs: date) }.map { $0.metricType })
    let confidence = calculateConfidence(
      requiredPresent: true,
      optionalMetrics: optionalMetrics,
      presentMetrics: presentMetrics
    )

    // Check persistence (use 3 days for Off state per PRD)
    let consecutiveDays = countConsecutiveDays(
      state: rawState,
      previousResults: previousResults,
      currentDate: date
    )

    // Stress uses 3-day persistence for "Alert" state
    let finalState: MonitorStateValue
    if rawState == .alert && consecutiveDays < 3 {
      finalState = .attention
    } else if rawState == .attention && consecutiveDays < 2 {
      finalState = .good
    } else {
      finalState = rawState
    }

    // Generate findings with ratio context
    let findings = generateFindings(
      signals: signals,
      state: finalState,
      acuteChronicRatio: acuteChronicRatio,
      hrvDecline: hrvDecline
    )

    return MonitorResult(
      monitorType: .stress,
      state: finalState,
      confidence: confidence,
      consecutiveDays: consecutiveDays,
      signals: signals,
      findings: findings
    )
  }

  // MARK: - Private Methods

  private func calculateHRVTrendDecline(samples: [DailyMetricSampleDTO], date: Date) -> Double? {
    let hrvSamples = samples
      .filter { $0.metricType == MonitorMetricType.heartRateVariability.rawValue }
      .sorted { $0.date < $1.date }

    guard hrvSamples.count >= 7 else { return nil }

    let calendar = Calendar.current
    let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: date)!

    let recentSamples = hrvSamples.filter { $0.date >= sevenDaysAgo }
    guard let baseline28Day = recentSamples.first?.baseline28Day, baseline28Day > 0 else { return nil }

    let recentAvg = recentSamples.reduce(0.0) { $0 + $1.value } / Double(recentSamples.count)
    return (baseline28Day - recentAvg) / baseline28Day
  }

  private func determineState(
    signals: [Signal],
    acuteChronicRatio: Double,
    hrvDecline: Double?
  ) -> MonitorStateValue {
    // Alert: Ratio > 1.5 OR HRV > 15% decline
    if acuteChronicRatio > 1.5 {
      return .alert
    }
    if let decline = hrvDecline, decline > 0.15 {
      return .alert
    }

    // Attention: Ratio 1.3-1.5 OR < 0.8 OR HRV declining 5-15%
    if acuteChronicRatio > 1.3 || acuteChronicRatio < 0.8 {
      return .attention
    }
    if let decline = hrvDecline, decline > 0.05 {
      return .attention
    }

    return .good
  }

  private func generateFindings(
    signals: [Signal],
    state: MonitorStateValue,
    acuteChronicRatio: Double,
    hrvDecline: Double?
  ) -> [Finding] {
    guard state != .good else { return [] }

    var findings: [Finding] = []

    // Format ratio for display
    let ratioPercent = Int((acuteChronicRatio - 1.0) * 100)
    let ratioDescription: String
    if acuteChronicRatio > 1.5 {
      ratioDescription = "Your recent training load is \(ratioPercent)% above your usual weekly average."
    } else if acuteChronicRatio > 1.3 {
      ratioDescription = "Your recent training load is \(ratioPercent)% higher than your usual."
    } else if acuteChronicRatio < 0.8 {
      ratioDescription = "Your recent training load is \(abs(ratioPercent))% below your usual."
    } else {
      ratioDescription = ""
    }

    if state == .alert {
      var explanation = ratioDescription
      if let decline = hrvDecline, decline > 0.15 {
        let declinePercent = Int(decline * 100)
        explanation += " Your HRV has also dropped \(declinePercent)% from your baseline."
      }
      explanation += " Consider taking a rest day or reducing intensity."

      findings.append(Finding(
        title: "Training load needs attention",
        explanation: explanation,
        confidence: hrvDecline != nil ? .high : .medium,
        relatedMetrics: [.activeEnergy] + (hrvDecline != nil ? [.heartRateVariability] : [])
      ))
    } else if state == .attention {
      var relatedMetrics: [MonitorMetricType] = []
      var explanation = ""

      if !ratioDescription.isEmpty {
        explanation = ratioDescription
        relatedMetrics.append(.activeEnergy)
      }

      if let decline = hrvDecline, decline > 0.05 {
        let declinePercent = Int(decline * 100)
        if !explanation.isEmpty { explanation += " " }
        explanation += "Your HRV is trending \(declinePercent)% below your baseline."
        relatedMetrics.append(.heartRateVariability)
      }

      explanation += " Keep an eye on how you're feeling."

      findings.append(Finding(
        title: "Training load trending high",
        explanation: explanation,
        confidence: relatedMetrics.count > 1 ? .medium : .low,
        relatedMetrics: relatedMetrics
      ))
    }

    return findings
  }

  // MARK: - Activity History Classification Methods

  /// Classifies user's activity history to determine if they're a beginner or returning exerciser
  private func classifyActivityHistory(
    samples: [DailyMetricSampleDTO],
    date: Date
  ) -> ActivityHistoryClassification {
    let calendar = Calendar.current

    // Filter to active energy samples only
    let energySamples = samples
      .filter { $0.metricType == MonitorMetricType.activeEnergy.rawValue }
      .sorted { $0.date < $1.date }

    // Need minimum data for meaningful classification
    // If not enough data, assume beginner
    guard energySamples.count >= ActivityThresholds.minimumDaysForClassification else {
      return .beginner
    }

    // Calculate recent 7-day average
    guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: date) else {
      return .beginner
    }
    let recentSamples = energySamples.filter { $0.date >= sevenDaysAgo && $0.date < date }
    let recentAverage = recentSamples.isEmpty ? 0 :
      recentSamples.reduce(0.0) { $0 + $1.value } / Double(recentSamples.count)

    // If recently active, no encouragement needed
    if recentAverage >= ActivityThresholds.lowActivityDailyAverage {
      return .active
    }

    // Recent activity is low - determine if beginner or returning
    let peakAverage = findPeakRollingAverage(
      samples: energySamples,
      windowDays: ActivityThresholds.peakWindowDays,
      beforeDate: date
    )

    if peakAverage >= ActivityThresholds.peakActivityThreshold {
      return .returning
    } else {
      return .beginner
    }
  }

  /// Finds the peak rolling average over the specified window in historical data
  private func findPeakRollingAverage(
    samples: [DailyMetricSampleDTO],
    windowDays: Int,
    beforeDate: Date
  ) -> Double {
    guard samples.count >= windowDays else {
      return samples.isEmpty ? 0 : samples.reduce(0.0) { $0 + $1.value } / Double(samples.count)
    }

    var peakAverage: Double = 0

    // Slide window through historical data
    for i in windowDays..<samples.count {
      let windowSamples = Array(samples[(i - windowDays)..<i])
      let average = windowSamples.reduce(0.0) { $0 + $1.value } / Double(windowSamples.count)
      peakAverage = max(peakAverage, average)
    }

    return peakAverage
  }

  /// Creates an encourage result with tailored messaging for beginner or returning users
  private func createEncourageResult(
    classification: ActivityHistoryClassification,
    date: Date
  ) -> MonitorResult {
    let finding: Finding

    switch classification {
    case .beginner:
      finding = Finding(
        title: "Ready to start your fitness journey?",
        explanation: "Starting a workout routine can feel overwhelming, but even small steps count. Try beginning with a 10-15 minute walk or a beginner-friendly workout. Your body will thank you!",
        confidence: .medium,
        relatedMetrics: [.activeEnergy]
      )
    case .returning:
      finding = Finding(
        title: "Time to get back in the game?",
        explanation: "We noticed you've been less active recently. Life happens! When you're ready, start slow and gradually build back up. Your body remembers more than you think.",
        confidence: .medium,
        relatedMetrics: [.activeEnergy]
      )
    case .active:
      // Should not happen, but handle gracefully
      finding = Finding(
        title: "Keep up the good work",
        explanation: "Your activity levels are looking healthy.",
        confidence: .low,
        relatedMetrics: [.activeEnergy]
      )
    }

    return MonitorResult(
      monitorType: .stress,
      state: .encourage,
      confidence: 0.7,
      consecutiveDays: 1,
      signals: [],
      findings: [finding]
    )
  }
}
