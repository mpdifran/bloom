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
  let optionalMetrics: [MonitorMetricType] = [
    .heartRateVariability,
    .heartRateRecovery,
    .sleepEfficiency,
    .deepSleep,
    .restingHeartRate
  ]

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

  // MARK: - Stress Type Classification

  /// Classification of detected stress pattern
  private enum StressType: Sendable {
    /// High training load causing physiological stress (overtraining)
    case trainingStress
    /// Normal/low training load with physiological stress signals (life stress, burnout)
    case burnout
    /// No stress detected
    case none
  }

  /// Result of HRV multi-day trend analysis
  private struct HRVTrendResult: Sendable {
    /// Percentage decline from 28-day baseline (positive = declining)
    let declinePercent: Double?
    /// Number of consecutive days HRV has been below baseline
    let consecutiveDecliningDays: Int
    /// Whether this represents a significant trend (3+ days AND >5% decline)
    var isSignificantTrend: Bool {
      guard let decline = declinePercent else { return false }
      return consecutiveDecliningDays >= 3 && decline > 0.05
    }
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

    // HRV multi-day trend analysis
    let hrvTrend = calculateHRVMultiDayTrend(samples: samples, date: date)

    // Add HRV signals based on trend
    if let decline = hrvTrend.declinePercent {
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

    // Collect burnout signals (sleep efficiency, deep sleep, RHR)
    let burnoutSignals = collectBurnoutSignals(samples: samples, date: date)

    // Detect stress type (training vs burnout)
    let stressType = detectStressType(
      acuteChronicRatio: acuteChronicRatio,
      hrvTrend: hrvTrend,
      burnoutSignals: burnoutSignals
    )

    // Combine all signals for the result
    var allSignals = signals
    if stressType == .burnout {
      allSignals.append(contentsOf: burnoutSignals)
      // Add HRV trend signal for burnout if significant
      if hrvTrend.isSignificantTrend, let decline = hrvTrend.declinePercent {
        // Only add if not already added above
        if !signals.contains(where: { $0.metricType == .heartRateVariability }) {
          allSignals.append(Signal(
            metricType: .heartRateVariability,
            date: date,
            zScore: decline * 10,
            direction: .lower,
            description: "HRV trending down for \(hrvTrend.consecutiveDecliningDays) days"
          ))
        }
      }
    }

    // Determine raw state based on stress type
    let rawState = determineState(
      stressType: stressType,
      acuteChronicRatio: acuteChronicRatio,
      hrvTrend: hrvTrend,
      burnoutSignals: burnoutSignals
    )

    // Calculate confidence
    let presentMetrics = Set(samples.filter { calendar.isDate($0.date, inSameDayAs: date) }.map { $0.metricType })
    let confidence = calculateConfidence(
      requiredPresent: true,
      optionalMetrics: optionalMetrics,
      presentMetrics: presentMetrics
    )

    // Check persistence with bypass for strong burnout patterns
    let shouldBypass = stressType == .burnout && shouldBypassPersistenceForBurnout(
      burnoutSignals: burnoutSignals,
      hrvTrend: hrvTrend
    )

    let consecutiveDays: Int
    let finalState: MonitorStateValue

    if shouldBypass {
      // Strong burnout pattern - bypass persistence, show immediately
      finalState = rawState
      consecutiveDays = 1
    } else {
      // Normal persistence rules
      let counted = countConsecutiveDays(
        state: rawState,
        previousResults: previousResults,
        currentDate: date
      )
      consecutiveDays = counted

      // Stress uses 3-day persistence for "Alert" state
      if rawState == .alert && consecutiveDays < 3 {
        finalState = .attention
      } else if rawState == .attention && consecutiveDays < 2 {
        finalState = .good
      } else {
        finalState = rawState
      }
    }

    // Generate findings based on stress type
    let findings: [Finding]
    let stressSubtype: StressSubtype?
    switch stressType {
    case .trainingStress:
      findings = generateTrainingStressFindings(
        state: finalState,
        acuteChronicRatio: acuteChronicRatio,
        hrvTrend: hrvTrend
      )
      stressSubtype = .trainingStress
    case .burnout:
      findings = generateBurnoutFindings(
        state: finalState,
        hrvTrend: hrvTrend,
        burnoutSignals: burnoutSignals
      )
      stressSubtype = .burnout
    case .none:
      findings = []
      stressSubtype = nil
    }

    return MonitorResult(
      monitorType: .stress,
      state: finalState,
      confidence: confidence,
      consecutiveDays: consecutiveDays,
      signals: allSignals,
      findings: findings,
      stressSubtype: stressSubtype
    )
  }

  // MARK: - Private Methods

  private func calculateHRVMultiDayTrend(
    samples: [DailyMetricSampleDTO],
    date: Date
  ) -> HRVTrendResult {
    let hrvSamples = samples
      .filter { $0.metricType == MonitorMetricType.heartRateVariability.rawValue }
      .sorted { $0.date < $1.date }

    guard hrvSamples.count >= 7 else {
      return HRVTrendResult(declinePercent: nil, consecutiveDecliningDays: 0)
    }

    let calendar = Calendar.current
    let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: date)!

    let recentSamples = hrvSamples.filter { $0.date >= sevenDaysAgo && $0.date <= date }
    guard let baseline28Day = recentSamples.first?.baseline28Day, baseline28Day > 0 else {
      return HRVTrendResult(declinePercent: nil, consecutiveDecliningDays: 0)
    }

    // Calculate overall decline percentage
    let recentAvg = recentSamples.reduce(0.0) { $0 + $1.value } / Double(recentSamples.count)
    let declinePercent = (baseline28Day - recentAvg) / baseline28Day

    // Count consecutive days below baseline (working backwards from current date)
    var consecutiveDeclining = 0
    let belowBaselineThreshold = baseline28Day * 0.95 // 5% below baseline

    for dayOffset in 0..<7 {
      guard let checkDate = calendar.date(byAdding: .day, value: -dayOffset, to: date),
            let sample = recentSamples.first(where: { calendar.isDate($0.date, inSameDayAs: checkDate) }),
            sample.value < belowBaselineThreshold else {
        break
      }
      consecutiveDeclining += 1
    }

    return HRVTrendResult(
      declinePercent: declinePercent,
      consecutiveDecliningDays: consecutiveDeclining
    )
  }

  /// Collects burnout-related signals from sleep and recovery metrics
  private func collectBurnoutSignals(
    samples: [DailyMetricSampleDTO],
    date: Date
  ) -> [Signal] {
    var signals: [Signal] = []
    let calendar = Calendar.current
    let todaySamples = samples.filter { calendar.isDate($0.date, inSameDayAs: date) }

    // Sleep Efficiency Signal (< 80% is concerning for burnout)
    if let efficiencySample = todaySamples.first(where: {
      $0.metricType == MonitorMetricType.sleepEfficiency.rawValue
    }) {
      let efficiency = efficiencySample.value / 100
      if efficiency < 0.80 {
        // Convert to approximate z-score (85% is typical baseline)
        let zScore = (0.85 - efficiency) * 20
        signals.append(Signal(
          metricType: .sleepEfficiency,
          date: date,
          zScore: zScore,
          direction: .lower,
          description: "Sleep efficiency is reduced"
        ))
      }
    }

    // Deep Sleep Signal (using z-score from baseline)
    if let deepSleepSample = todaySamples.first(where: {
      $0.metricType == MonitorMetricType.deepSleep.rawValue
    }),
       let zScore = deepSleepSample.zScore, zScore < -1.0 {
      let baseline = deepSleepSample.baseline7Day ?? deepSleepSample.baseline28Day
      let difference = baseline.map { deepSleepSample.value - $0 }
      signals.append(Signal(
        metricType: .deepSleep,
        date: date,
        zScore: zScore,
        direction: .lower,
        description: "Deep sleep is below your usual",
        difference: difference
      ))
    }

    // Elevated RHR Signal (using z-score from baseline)
    if let rhrSample = todaySamples.first(where: {
      $0.metricType == MonitorMetricType.restingHeartRate.rawValue
    }),
       let zScore = rhrSample.zScore, zScore > 1.0 {
      let baseline = rhrSample.baseline28Day ?? rhrSample.baseline7Day
      let difference = baseline.map { rhrSample.value - $0 }
      signals.append(Signal(
        metricType: .restingHeartRate,
        date: date,
        zScore: zScore,
        direction: .higher,
        description: "Resting heart rate is elevated",
        difference: difference
      ))
    }

    return signals
  }

  /// Determines whether the stress pattern is training-related or burnout
  private func detectStressType(
    acuteChronicRatio: Double,
    hrvTrend: HRVTrendResult,
    burnoutSignals: [Signal]
  ) -> StressType {
    let isHighLoad = acuteChronicRatio > 1.3
    let stressSignalCount = burnoutSignals.count + (hrvTrend.isSignificantTrend ? 1 : 0)

    // High training load = training stress (regardless of other signals)
    if isHighLoad {
      return .trainingStress
    }

    // Normal/low load but multiple stress signals = burnout
    if stressSignalCount >= 2 {
      return .burnout
    }

    return .none
  }

  /// Determines if persistence rule should be bypassed for strong burnout patterns
  private func shouldBypassPersistenceForBurnout(
    burnoutSignals: [Signal],
    hrvTrend: HRVTrendResult
  ) -> Bool {
    // Bypass if HRV declining 3+ consecutive days AND at least one other signal
    if hrvTrend.consecutiveDecliningDays >= 3 && !burnoutSignals.isEmpty {
      return true
    }

    // Bypass if 2+ high-severity signals (z-score magnitude > 2.0)
    let highSeveritySignals = burnoutSignals.filter { abs($0.zScore) > 2.0 }
    if highSeveritySignals.count >= 2 {
      return true
    }

    return false
  }

  private func determineState(
    stressType: StressType,
    acuteChronicRatio: Double,
    hrvTrend: HRVTrendResult,
    burnoutSignals: [Signal]
  ) -> MonitorStateValue {
    switch stressType {
    case .trainingStress:
      // Alert: Ratio > 1.5 OR HRV > 15% decline
      if acuteChronicRatio > 1.5 {
        return .alert
      }
      if let decline = hrvTrend.declinePercent, decline > 0.15 {
        return .alert
      }

      // Attention: Ratio 1.3-1.5 OR < 0.8 OR HRV declining 5-15%
      if acuteChronicRatio > 1.3 || acuteChronicRatio < 0.8 {
        return .attention
      }
      if let decline = hrvTrend.declinePercent, decline > 0.05 {
        return .attention
      }

      return .good

    case .burnout:
      // Count total stress indicators
      let totalSignalCount = burnoutSignals.count + (hrvTrend.isSignificantTrend ? 1 : 0)
      let hasHighSeveritySignal = burnoutSignals.contains { abs($0.zScore) > 2.0 }

      // Alert: 3+ signals OR any high-severity signal OR HRV declining 5+ consecutive days
      if totalSignalCount >= 3 || hasHighSeveritySignal || hrvTrend.consecutiveDecliningDays >= 5 {
        return .alert
      }

      // Attention: 2 signals (which is the threshold for burnout detection)
      return .attention

    case .none:
      return .good
    }
  }

  private func generateTrainingStressFindings(
    state: MonitorStateValue,
    acuteChronicRatio: Double,
    hrvTrend: HRVTrendResult
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
      if let decline = hrvTrend.declinePercent, decline > 0.15 {
        let declinePercent = Int(decline * 100)
        explanation += " Your HRV has also dropped \(declinePercent)% from your baseline."
      }
      explanation += " Consider taking a rest day or reducing intensity."

      findings.append(Finding(
        title: "Training load needs attention",
        explanation: explanation,
        confidence: hrvTrend.declinePercent != nil ? .high : .medium,
        relatedMetrics: [.activeEnergy] + (hrvTrend.declinePercent != nil ? [.heartRateVariability] : [])
      ))
    } else if state == .attention {
      var relatedMetrics: [MonitorMetricType] = []
      var explanation = ""

      if !ratioDescription.isEmpty {
        explanation = ratioDescription
        relatedMetrics.append(.activeEnergy)
      }

      if let decline = hrvTrend.declinePercent, decline > 0.05 {
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

  private func generateBurnoutFindings(
    state: MonitorStateValue,
    hrvTrend: HRVTrendResult,
    burnoutSignals: [Signal]
  ) -> [Finding] {
    guard state != .good else { return [] }

    var findings: [Finding] = []

    // Build explanation from detected signals
    var signalDescriptions: [String] = []

    if hrvTrend.isSignificantTrend, let decline = hrvTrend.declinePercent {
      let declinePercent = Int(decline * 100)
      signalDescriptions.append("HRV has declined \(declinePercent)% over \(hrvTrend.consecutiveDecliningDays) days")
    }

    for signal in burnoutSignals {
      switch signal.metricType {
      case .sleepEfficiency:
        signalDescriptions.append("sleep efficiency is reduced")
      case .deepSleep:
        signalDescriptions.append("deep sleep is below your usual")
      case .restingHeartRate:
        signalDescriptions.append("resting heart rate is elevated")
      default:
        break
      }
    }

    var explanation = "Your training load is normal, but your body is showing signs of stress. "

    if !signalDescriptions.isEmpty {
      explanation += "We noticed: \(signalDescriptions.joined(separator: ", ")). "
    }

    explanation += "This pattern may indicate life stress, chronic fatigue, or the need for extra recovery. Consider prioritizing rest, stress management, and sleep quality."

    // Collect related metrics
    var relatedMetrics: [MonitorMetricType] = []
    if hrvTrend.isSignificantTrend {
      relatedMetrics.append(.heartRateVariability)
    }
    relatedMetrics.append(contentsOf: burnoutSignals.map { $0.metricType })

    findings.append(Finding(
      title: state == .alert ? "Signs of burnout detected" : "Possible burnout pattern emerging",
      explanation: explanation,
      confidence: burnoutSignals.count >= 2 ? .high : .medium,
      relatedMetrics: relatedMetrics
    ))

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
