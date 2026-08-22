//
//  MetricSignalRow.swift
//  Bloom
//
//  Created by Claude on 2026-01-10.
//

import SwiftUI
import SFSafeSymbols

/// A row displaying a single metric signal with its deviation and severity.
struct MetricSignalRow: View {

  let signal: Signal

  var body: some View {
    HStack(spacing: 12) {
      // Icon
      Image(systemSymbol: signal.metricType.icon)
        .font(.title3)
        .foregroundStyle(signal.severity.color)
        .frame(width: 32, height: 32)

      // Labels
      VStack(alignment: .leading, spacing: 2) {
        Text(signal.metricType.displayName)
          .font(.subheadline)
          .fontWeight(.medium)

        Text(signal.description)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(2)
      }

      Spacer()

      // Z-score badge
      zScoreBadge
    }
  }

  private var zScoreBadge: some View {
    HStack(spacing: 4) {
      Image(systemSymbol: signal.direction == .higher ? .arrowUp : .arrowDown)
        .font(.caption2)

      Text(signal.magnitude.formatted(.number.precision(.fractionLength(1))))
        .font(.caption)
        .fontWeight(.medium)
    }
    .foregroundStyle(signal.severity.color)
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(signal.severity.color.opacity(0.15), in: Capsule())
  }
}

// MARK: - Preview

#Preview {
  PreviewEnvironment {
    VStack(spacing: 12) {
      MetricSignalRow(signal: Signal(
        metricType: .restingHeartRate,
        date: Date(),
        zScore: 1.5,
        direction: .higher,
        description: "Your resting heart rate is elevated"
      ))

      MetricSignalRow(signal: Signal(
        metricType: .heartRateVariability,
        date: Date(),
        zScore: -2.1,
        direction: .lower,
        description: "Your HRV has dropped significantly below your baseline"
      ))

      MetricSignalRow(signal: Signal(
        metricType: .sleepDuration,
        date: Date(),
        zScore: -0.8,
        direction: .lower,
        description: "You slept less than usual"
      ))
    }
    .cardContainer()
    .padding()
  }
}
