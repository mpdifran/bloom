//
//  SignalSummaryRow.swift
//  Bloom
//
//  Created by Claude on 2026-01-13.
//

import SwiftUI
import SFSafeSymbols

/// A compact signal row for displaying elevated/high severity signals on MonitorCard.
/// Shows icon, metric name, and directional trend indicator.
struct SignalSummaryRow: View {

  let signal: Signal

  var body: some View {
    HStack(spacing: 10) {
      Image(systemSymbol: signal.metricType.icon)
        .font(.caption)
        .foregroundStyle(signal.severity.color)
        .frame(width: 20)

      Text(signal.metricType.displayName)
        .font(.subheadline)
        .fontWeight(.medium)

      Spacer()

      trendBadge
    }
  }

  private var trendBadge: some View {
    HStack(spacing: 2) {
      Image(systemSymbol: trendIcon)
        .font(.caption2)

      if let difference = signal.difference {
        Text(signal.metricType.formatDifference(difference))
          .font(.caption2)
      }
    }
    .fontWeight(.medium)
    .foregroundStyle(signal.severity.color)
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(signal.severity.color.opacity(0.15), in: Capsule())
  }

  private var trendIcon: SFSymbol {
    switch signal.direction {
    case .higher:
      return .arrowUp
    case .lower:
      return .arrowDown
    case .variable:
      return .arrowUpArrowDown
    }
  }
}

// MARK: - Preview

#Preview {
  PreviewEnvironment {
    VStack(spacing: 8) {
      SignalSummaryRow(signal: Signal(
        metricType: .restingHeartRate,
        date: Date(),
        zScore: 1.5,
        direction: .higher,
        description: "Your resting heart rate is elevated",
        difference: 8
      ))

      SignalSummaryRow(signal: Signal(
        metricType: .heartRateVariability,
        date: Date(),
        zScore: -2.1,
        direction: .lower,
        description: "Your HRV has dropped significantly",
        difference: -15
      ))

      SignalSummaryRow(signal: Signal(
        metricType: .sleepDuration,
        date: Date(),
        zScore: -1.3,
        direction: .lower,
        description: "You slept less than usual",
        difference: -45
      ))
    }
    .cardContainer()
    .padding()
  }
}
