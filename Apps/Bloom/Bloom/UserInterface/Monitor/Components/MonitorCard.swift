//
//  MonitorCard.swift
//  Bloom
//
//  Created by Claude on 2026-01-09.
//

import SwiftUI
import SFSafeSymbols
import DataContainer

/// A card displaying the state of a single health monitor.
/// Expands to show findings when in Watch or Off state.
struct MonitorCard: View {

  let result: MonitorResult

  @State private var rangeData: [MetricRangeData] = []

  /// Whether the card should show expanded content (metrics and findings)
  private var isExpanded: Bool {
    result.state.isConcerning && !result.findings.isEmpty
  }

  /// Signals with elevated or high severity (z-score >= 1.0)
  private var elevatedSignals: [Signal] {
    result.signals.filter { $0.severity >= .elevated }
  }

  var body: some View {
    NavigationLink(value: result.monitorType) {
      VStack(alignment: .leading, spacing: 0) {
        headerView

        if result.state == .good && !elevatedSignals.isEmpty {
          signalSummarySection
        }

        if isExpanded {
          if !rangeData.isEmpty {
            Divider()
              .padding(.vertical, 12)

            metricsSection
          }

          if !result.findings.isEmpty {
            Divider()
              .padding(.vertical, 12)

            findingsView
          }
        }
      }
      .cardContainer()
    }
    .buttonStyle(.plain)
    .task {
      await loadRangeData()
    }
  }

}

private extension MonitorCard {

  func loadRangeData() async {
    let metrics: [(type: String, displayName: String)] = result.monitorType.metrics.map {
      ($0.rawValue, $0.displayName)
    }

    do {
      let actor = DailyMetricSampleModelActor.standard()
      rangeData = try await actor.fetchRangeData(metricTypes: metrics, for: Date())
    } catch {
      rangeData = []
    }
  }

  // MARK: - Header

  var headerView: some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 2) {
        Text(result.monitorType.displayName)
          .font(.headline)
          .fontWeight(.semibold)

        Text(subtitleText)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      Spacer()

      stateBadge

      Image(systemSymbol: .chevronRight)
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(.tertiary)
    }
  }

  var stateBadge: some View {
    Text(result.state.displayName)
      .font(.caption)
      .fontWeight(.medium)
      .foregroundStyle(badgeTextColor)
      .padding(.horizontal, 10)
      .padding(.vertical, 5)
      .background(badgeBackgroundColor, in: Capsule())
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

  // MARK: - Metrics

  var metricsSection: some View {
    VStack(spacing: 8) {
      ForEach(rangeData) { data in
        if let metricType = MonitorMetricType(rawValue: data.metricType) {
          MetricRangeRowCondensed(rangeData: data, metricType: metricType)
        }
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

  var badgeBackgroundColor: some ShapeStyle {
    badgeTextColor.tertiary
  }

  var badgeTextColor: Color {
    switch result.state {
    case .good:
      return .mutedGreen
    case .attention:
      return .mutedOrange
    case .alert:
      return .mutedRed
    case .unavailable:
      return .gray
    case .encourage:
      return .mutedBlue
    }
  }

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
