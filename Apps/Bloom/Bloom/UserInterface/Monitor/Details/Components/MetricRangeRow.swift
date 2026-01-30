//
//  MetricRangeRow.swift
//  Bloom
//
//  Created by Claude on 2026-01-12.
//

import SwiftUI
import SFSafeSymbols
import DataContainer

/// A full metric row displaying icon, name, value, and z-score range bar.
/// Used in detail views to show comprehensive metric information.
struct MetricRangeRow: View {

  let rangeData: MetricRangeData
  let metricType: MonitorMetricType

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // Header with icon, name, and current value
      HStack(spacing: 10) {
        Image(systemSymbol: metricType.icon)
          .font(.body)
          .foregroundStyle(.secondary)
          .frame(width: 24)

        Text(rangeData.displayName)
          .font(.subheadline)
          .fontWeight(.medium)

        Spacer()

        if let value = rangeData.currentValue {
          Text(metricType.formatValue(value))
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.primary)
        } else {
          Text("No data")
            .font(.subheadline)
            .foregroundStyle(.tertiary)
        }
      }

      // Z-score range bar
      MonitorSummaryBar(
        data: MonitorSummaryBarData(from: rangeData) ?? .empty,
        lowLabel: lowLabel,
        normalLabel: normalLabel,
        highLabel: highLabel
      )
    }
  }

  // Custom labels for time-based metrics
  private var lowLabel: String {
    metricType == .bedtime || metricType == .wakeTime ? "Early" : "Low"
  }

  private var normalLabel: String { "Typical" }

  private var highLabel: String {
    metricType == .bedtime || metricType == .wakeTime ? "Late" : "High"
  }

  private var tintColor: Color {
    // Color based on z-score magnitude
    guard let zScore = rangeData.zScore else { return .accentColor }
    let magnitude = abs(zScore)
    if magnitude < 1.0 {
      return .green
    } else if magnitude < 2.0 {
      return .orange
    } else {
      return .red
    }
  }
}

/// A condensed version of the metric row for use in MonitorCard.
/// Shows only icon and chart, minimal labels.
struct MetricRangeRowCondensed: View {

  let rangeData: MetricRangeData
  let metricType: MonitorMetricType

  var body: some View {
    HStack(spacing: 8) {
      Image(systemSymbol: metricType.icon)
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(width: 20)

      MonitorSummaryBar(
        data: MonitorSummaryBarData(from: rangeData) ?? .empty,
        hasData: MonitorSummaryBarData(from: rangeData) == nil ? false : true
      )

      if let value = rangeData.currentValue {
        Text(metricType.formatValueShort(value))
          .font(.caption2)
          .fontWeight(.medium)
          .foregroundStyle(.secondary)
          .frame(width: 40, alignment: .trailing)
      } else {
        Text("--")
          .font(.caption2)
          .foregroundStyle(.tertiary)
          .frame(width: 40, alignment: .trailing)
      }
    }
  }

  private var tintColor: Color {
    guard let zScore = rangeData.zScore else { return .accentColor }
    let magnitude = abs(zScore)
    if magnitude < 1.0 {
      return .green
    } else if magnitude < 2.0 {
      return .orange
    } else {
      return .red
    }
  }
}

// MARK: - Preview

#Preview("Full Row") {
  PreviewEnvironment {
    VStack(spacing: 16) {
      MetricRangeRow(
        rangeData: MetricRangeData(
          metricType: "restingHeartRate",
          displayName: "Resting Heart Rate",
          currentValue: 62,
          min7Day: 55,
          max7Day: 68,
          baseline28Day: 60,
          zScore: 0.5,
          min7DayZScore: -0.3,
          max7DayZScore: 0.8
        ),
        metricType: .restingHeartRate
      )

      Divider()

      MetricRangeRow(
        rangeData: MetricRangeData(
          metricType: "heartRateVariability",
          displayName: "Heart Rate Variability",
          currentValue: 28,
          min7Day: 28,
          max7Day: 52,
          baseline28Day: 42,
          zScore: -1.5,
          min7DayZScore: -1.8,
          max7DayZScore: 0.2
        ),
        metricType: .heartRateVariability
      )

      Divider()

      MetricRangeRow(
        rangeData: MetricRangeData(
          metricType: "sleepDuration",
          displayName: "Sleep Duration",
          currentValue: 420,
          min7Day: 380,
          max7Day: 480,
          baseline28Day: 440,
          zScore: -0.3,
          min7DayZScore: -0.8,
          max7DayZScore: 0.5
        ),
        metricType: .sleepDuration
      )
    }
    .cardContainer()
    .padding()
  }
}

#Preview("Condensed Row") {
  PreviewEnvironment {
    VStack(spacing: 8) {
      MetricRangeRowCondensed(
        rangeData: MetricRangeData(
          metricType: "restingHeartRate",
          displayName: "Resting Heart Rate",
          currentValue: 62,
          min7Day: 55,
          max7Day: 68,
          baseline28Day: 60,
          zScore: 0.5,
          min7DayZScore: -0.3,
          max7DayZScore: 0.8
        ),
        metricType: .restingHeartRate
      )

      MetricRangeRowCondensed(
        rangeData: MetricRangeData(
          metricType: "heartRateVariability",
          displayName: "HRV",
          currentValue: 28,
          min7Day: 28,
          max7Day: 52,
          baseline28Day: 42,
          zScore: -1.5,
          min7DayZScore: -1.8,
          max7DayZScore: 0.2
        ),
        metricType: .heartRateVariability
      )

      MetricRangeRowCondensed(
        rangeData: MetricRangeData(
          metricType: "activeEnergy",
          displayName: "Active Energy",
          currentValue: 650,
          min7Day: 320,
          max7Day: 650,
          baseline28Day: 450,
          zScore: 2.1,
          min7DayZScore: 0.5,
          max7DayZScore: 2.3
        ),
        metricType: .remSleep
      )
    }
    .padding()
  }
}
