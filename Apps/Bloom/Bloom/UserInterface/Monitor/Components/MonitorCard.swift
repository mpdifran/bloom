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

  @State private var isExpanded: Bool = false
  @State private var rangeData: [MetricRangeData] = []

  var body: some View {
    NavigationLink(value: result.monitorType) {
      VStack(alignment: .leading, spacing: 0) {
        headerView

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
      .cardContainer(fill: backgroundColor)
    }
    .buttonStyle(.plain)
    .onAppear {
      // Auto-expand if there are concerning findings
      isExpanded = result.state.isConcerning && !result.findings.isEmpty
    }
    .task {
      await loadRangeData()
    }
  }

  private func loadRangeData() async {
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

  private var headerView: some View {
    HStack(spacing: 12) {
      iconView

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

  private var iconView: some View {
    Image(systemSymbol: monitorIcon)
      .font(.title2)
      .foregroundStyle(iconColor)
      .frame(width: 32, height: 32)
  }

  private var stateBadge: some View {
    Text(result.state.displayName)
      .font(.caption)
      .fontWeight(.medium)
      .foregroundStyle(badgeTextColor)
      .padding(.horizontal, 10)
      .padding(.vertical, 5)
      .background(badgeBackgroundColor, in: Capsule())
  }

  // MARK: - Metrics

  private var metricsSection: some View {
    VStack(spacing: 8) {
      ForEach(rangeData) { data in
        if let metricType = MonitorMetricType(rawValue: data.metricType) {
          MetricRangeRowCondensed(rangeData: data, metricType: metricType)
        }
      }
    }
  }

  // MARK: - Findings

  private var findingsView: some View {
    VStack(alignment: .leading, spacing: 12) {
      ForEach(result.findings) { finding in
        MonitorFindingCell(finding: finding)
      }
    }
  }

  // MARK: - Styling

  private var monitorIcon: SFSymbol {
    switch result.monitorType {
    case .recovery:
      return .heartFill
    case .stress:
      return .flameFill
    case .sleep:
      return .moonFill
    }
  }

  private var iconColor: Color {
    switch result.state {
    case .good:
      return .green
    case .attention:
      return .orange
    case .alert:
      return .red
    case .unavailable:
      return .gray
    case .encourage:
      return .blue
    }
  }

  private var backgroundColor: Color {
    Color(.systemBackground)
  }

  private var badgeBackgroundColor: Color {
    switch result.state {
    case .good:
      return .green.opacity(0.15)
    case .attention:
      return .orange.opacity(0.15)
    case .alert:
      return .red.opacity(0.15)
    case .unavailable:
      return .gray.opacity(0.15)
    case .encourage:
      return .blue.opacity(0.15)
    }
  }

  private var badgeTextColor: Color {
    switch result.state {
    case .good:
      return .green
    case .attention:
      return .orange
    case .alert:
      return .red
    case .unavailable:
      return .gray
    case .encourage:
      return .blue
    }
  }

  private var subtitleText: String {
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
    VStack(spacing: 16) {
      MonitorCard(result: MonitorResult(
        monitorType: .recovery,
        state: .good,
        confidence: 0.85,
        consecutiveDays: 1,
        signals: [],
        findings: []
      ))

      MonitorCard(result: MonitorResult(
        monitorType: .stress,
        state: .attention,
        confidence: 0.72,
        consecutiveDays: 2,
        signals: [],
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
        signals: [],
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
    .padding()
  }
}
