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

  @ObservedObject private var preferences = MonitorNotificationPreferences.shared
  @State private var summaryBarData: MonitorSummaryBarData?

  /// Whether the card should show expanded content (findings)
  private var isExpanded: Bool {
    result.state.isConcerning && !result.findings.isEmpty
  }

  /// The data to display - real data or empty placeholder
  private var displayBarData: MonitorSummaryBarData {
    summaryBarData ?? .empty
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      headerView

      MonitorSummaryBar(data: displayBarData)
        .padding(.top, 12)

      if isExpanded {
        Divider()
          .padding(.vertical, 12)

        findingsView
      }
    }
    .animation(.default, value: summaryBarData?.metricZScores.map(\.metricType))
    .cardContainer()
    .contextMenu {
      // Only show "Turn On" if currently off or snoozed
      if !preferences.isEnabled(for: result.monitorType) || preferences.isSnoozed(for: result.monitorType) {
        Button {
          preferences.clearSnooze(for: result.monitorType)
          preferences.setEnabled(true, for: result.monitorType)
        } label: {
          Label("Turn On Notifications", systemSymbol: .bell)
        }
      }

      // Only show snooze options if enabled and not already snoozed
      if preferences.isEnabled(for: result.monitorType) && !preferences.isSnoozed(for: result.monitorType) {
        Divider()

        ForEach(MonitorNotificationPreferences.SnoozeDuration.allCases, id: \.self) { duration in
          Button {
            preferences.snooze(result.monitorType, for: duration.timeInterval)
          } label: {
            Label("Snooze for \(duration.displayName)", systemSymbol: .moonZzz)
          }
        }

        Divider()

        Button {
          preferences.setEnabled(false, for: result.monitorType)
        } label: {
          Label("Turn Off Notifications", systemSymbol: .bellSlash)
        }
      }
    }
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

    // Fetch all stress detection metrics (HRR, HRV, sleep efficiency, deep sleep, RHR)
    let metricsData = try await actor.fetchSummaryBarData(
      metricTypes: MonitorType.stress.detectionMetrics.map { $0.rawValue },
      for: Date()
    )

    // If no training load data, fall back to metrics-only data
    guard let summary = trainingLoadSummary else {
      return metricsData
    }

    // Convert training load to z-score (10% = 1 z-score)
    let trainingLoadZScore = summary.percentageDifference / 10.0
    let minZScore = trainingLoadZScore
    let maxZScore = trainingLoadZScore

    // Combine with other metrics data if available
    var metricZScores = [MetricZScorePoint(metricType: "trainingLoad", zScore: trainingLoadZScore)]

    if let metricsData {
      metricZScores.append(contentsOf: metricsData.metricZScores)
      // Expand range to include other metrics data
      return MonitorSummaryBarData(
        metricZScores: metricZScores,
        minZScore: min(minZScore, metricsData.minZScore),
        maxZScore: max(maxZScore, metricsData.maxZScore)
      )
    }

    return MonitorSummaryBarData(
      metricZScores: metricZScores,
      minZScore: minZScore,
      maxZScore: maxZScore
    )
  }

  // MARK: - Header

  var headerView: some View {
    HStack(alignment: .top, spacing: 12) {
      VStack(alignment: .leading, spacing: 2) {
        Text(result.monitorType.displayName)
          .font(.headline)
          .fontWeight(.semibold)

        subtitleView
      }

      Spacer()

      HStack {
        MonitorStateBadge(state: result.state)

        Image(systemSymbol: .chevronForward)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }

  var subtitleView: some View {
    HStack(spacing: 4) {
      Text(subtitleText)

      if preferences.isSnoozed(for: result.monitorType) {
        Text(verbatim: "•")
        Image(systemSymbol: .bellSlashFill)
          .foregroundStyle(.mutedYellow)
          .font(.caption)
      }
    }
    .font(.subheadline)
    .foregroundStyle(.secondary)
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
      return String(localized: "Insufficient data", comment: "Monitor card subtitle when there is not enough data to evaluate")
    }

    if result.state == .encourage {
      return String(localized: "Ready when you are", comment: "Monitor card subtitle when the monitor is idle and waiting")
    }

    // Get signals with significant deviations (|zScore| > 1.0)
    let significantSignals = result.signals.filter { abs($0.zScore) > 1.0 }

    if significantSignals.isEmpty {
      return String(localized: "All metrics typical", comment: "Monitor card subtitle when no metric deviates from baseline")
    }

    // Format as "HRV low, RHR high"
    let summaries = significantSignals.prefix(3).map { signal in
      let directionText: String
      switch signal.direction {
      case .higher:
        directionText = String(localized: "high", comment: "Direction of a monitor signal deviation, shown after a metric name")
      case .lower:
        directionText = String(localized: "low", comment: "Direction of a monitor signal deviation, shown after a metric name")
      case .variable:
        directionText = String(localized: "variable", comment: "Direction of a monitor signal deviation, shown after a metric name")
      }
      return String(
        localized: "\(signal.metricType.shortName) \(directionText)",
        comment: "Monitor card subtitle item pairing a metric short name with its deviation direction, e.g. 'HRV low'"
      )
    }

    return summaries.joined(separator: ", ")
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
              metricType: .remSleep,
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
              relatedMetrics: [.remSleep]
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
