//
//  MonitorCard.swift
//  Bloom
//
//  Created by Claude on 2026-01-09.
//

import SwiftUI
import SFSafeSymbols
import DataContainer
import CoreHealth

/// A card displaying the state of a single health monitor.
/// Expands to show findings when in Watch or Off state.
struct MonitorCard: View {

  let result: MonitorResult

  @State private var summaryBarData: MonitorSummaryBarData?

  /// Whether the card should show expanded content (findings)
  private var isExpanded: Bool {
    result.state.isConcerning && !result.findings.isEmpty
  }

  /// Signals with elevated or high severity (z-score >= 1.0)
  private var elevatedSignals: [Signal] {
    result.signals.filter { $0.severity >= .elevated }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      headerView

      if let summaryBarData {
        MonitorSummaryBar(data: summaryBarData)
          .padding(.top, 12)
      }

      if result.state == .good && !elevatedSignals.isEmpty {
        signalSummarySection
      }

      if isExpanded {
        Divider()
          .padding(.vertical, 12)

        findingsView
      }
    }
    .cardContainer()
    .task {
      await loadSummaryBarData()
    }
  }

}

private extension MonitorCard {

  func loadSummaryBarData() async {
    do {
      let actor = DailyMetricSampleModelActor.standard()

      // For stress monitor, include training load data
      if result.monitorType == .stress {
        summaryBarData = try await loadStressSummaryBarData(actor: actor)
      } else {
        summaryBarData = try await actor.fetchSummaryBarData(
          metricTypes: result.monitorType.metrics.map { $0.rawValue },
          for: Date()
        )
      }
    } catch {
      summaryBarData = nil
    }
  }

  /// Loads summary bar data for the stress monitor, including training load z-scores.
  func loadStressSummaryBarData(actor: DailyMetricSampleModelActor) async throws -> MonitorSummaryBarData? {
    // Fetch training load summary
    let trainingLoadSummary = await HealthStoreFetcher.shared.fetchTrainingLoadSummary()

    // Fetch any heart rate recovery data
    let hrrData = try await actor.fetchSummaryBarData(
      metricTypes: [MonitorMetricType.heartRateRecovery.rawValue],
      for: Date()
    )

    // If no training load data, fall back to HRR-only data
    guard let summary = trainingLoadSummary else {
      return hrrData
    }

    // Convert training load to z-score (10% = 1 z-score)
    let trainingLoadZScore = summary.percentageDifference / 10.0
    let (minZScore, maxZScore) = calculateTrainingLoadZScoreRange(summary: summary)

    // Combine with HRR data if available
    var metricZScores = [MetricZScorePoint(metricType: "trainingLoad", zScore: trainingLoadZScore)]

    if let hrrData {
      metricZScores.append(contentsOf: hrrData.metricZScores)
      // Expand range to include HRR data
      return MonitorSummaryBarData(
        metricZScores: metricZScores,
        min7DayZScore: min(minZScore, hrrData.min7DayZScore),
        max7DayZScore: max(maxZScore, hrrData.max7DayZScore)
      )
    }

    return MonitorSummaryBarData(
      metricZScores: metricZScores,
      min7DayZScore: minZScore,
      max7DayZScore: maxZScore
    )
  }

  /// Calculates the min/max z-scores from training load trend data for the past 7 days.
  func calculateTrainingLoadZScoreRange(summary: TrainingLoadSummary) -> (min: Double, max: Double) {
    var zScores: [Double] = []
    let trendCount = summary.sevenDayTrend.count
    let startIndex = max(0, trendCount - 7)

    for index in startIndex..<trendCount {
      guard index < summary.twentyEightDayTrend.count else { continue }
      let sevenDayPoint = summary.sevenDayTrend[index]
      let twentyEightDayValue = summary.twentyEightDayTrend[index].value

      guard twentyEightDayValue > 0 else { continue }

      let percentDiff = ((sevenDayPoint.value - twentyEightDayValue) / twentyEightDayValue) * 100
      zScores.append(percentDiff / 10.0)
    }

    guard !zScores.isEmpty else {
      let currentZScore = summary.percentageDifference / 10.0
      return (currentZScore, currentZScore)
    }

    return (zScores.min() ?? 0, zScores.max() ?? 0)
  }

  // MARK: - Header

  var headerView: some View {
    HStack(alignment: .top, spacing: 12) {
      VStack(alignment: .leading, spacing: 2) {
        Text(result.monitorType.displayName)
          .font(.headline)
          .fontWeight(.semibold)

        Text(subtitleText)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      Spacer()

      MonitorStateBadge(state: result.state)
    }
  }

  // MARK: - Signal Summary

  var signalSummarySection: some View {
    VStack(alignment: .leading, spacing: 6) {
      Divider()
        .padding(.vertical, 10)

      ForEach(elevatedSignals) { signal in
        SignalSummaryRow(signal: signal)
      }
    }
  }

  // MARK: - Findings

  var findingsView: some View {
    VStack(alignment: .leading, spacing: 12) {
      ForEach(result.findings) { finding in
        MonitorFindingCell(finding: finding)
      }
    }
  }

  // MARK: - Styling

  var subtitleText: String {
    if result.state == .unavailable {
      return "Insufficient data"
    }

    if result.state == .encourage {
      return "Ready when you are"
    }

    let confidencePercent = Int(result.confidence * 100)
    if result.consecutiveDays > 1 {
      return "\(result.consecutiveDays) days • \(confidencePercent)% confidence"
    }
    return "\(confidencePercent)% confidence"
  }
}

// MARK: - Preview

#Preview {
  PreviewEnvironment {
    NavigationStack {
      BloomScrollView {
        MonitorCard(result: MonitorResult(
          monitorType: .recovery,
          state: .good,
          confidence: 0.85,
          consecutiveDays: 1,
          signals: [
            Signal(
              metricType: .restingHeartRate,
              date: Date(),
              zScore: 1.2,
              direction: .higher,
              description: "Resting heart rate is slightly elevated",
              difference: 6
            )
          ],
          findings: []
        ))
        
        MonitorCard(result: MonitorResult(
          monitorType: .stress,
          state: .attention,
          confidence: 0.72,
          consecutiveDays: 2,
          signals: [
            Signal(
              metricType: .activeEnergy,
              date: Date(),
              zScore: 1.8,
              direction: .higher,
              description: "Training load is elevated"
            )
          ],
          findings: [
            Finding(
              title: "Training load trending high",
              explanation: "Your recent training load is 25% above your usual. Keep an eye on how you're feeling.",
              confidence: .medium,
              relatedMetrics: [.activeEnergy]
            )
          ]
        ))
        
        MonitorCard(result: MonitorResult(
          monitorType: .sleep,
          state: .alert,
          confidence: 0.90,
          consecutiveDays: 3,
          signals: [
            Signal(
              metricType: .sleepDuration,
              date: Date(),
              zScore: -2.3,
              direction: .lower,
              description: "Sleep duration is very low"
            ),
            Signal(
              metricType: .bedtime,
              date: Date(),
              zScore: 1.5,
              direction: .variable,
              description: "Bedtime has been inconsistent"
            )
          ],
          findings: [
            Finding(
              title: "Sleep duration is very low",
              explanation: "You've been getting significantly less sleep than your usual for the past few days.",
              confidence: .high,
              relatedMetrics: [.sleepDuration]
            ),
            Finding(
              title: "Your bedtime has been inconsistent",
              explanation: "Your bedtime has varied by about 75 minutes over the past week.",
              confidence: .medium,
              relatedMetrics: [.bedtime, .wakeTime]
            )
          ]
        ))
      }
    }
  }
}
