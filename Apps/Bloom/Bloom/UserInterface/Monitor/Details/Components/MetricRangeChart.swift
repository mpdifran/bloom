//
//  MetricRangeChart.swift
//  Bloom
//
//  Created by Claude on 2026-01-12.
//

import SwiftUI
import DataContainer

/// A minimalist horizontal bar chart showing a metric's 7-day range with baseline marker.
/// Inspired by Apple's Vitals feature UI.
struct MetricRangeChart: View {

  let rangeData: MetricRangeData

  /// Whether to show the condensed version (smaller height, no labels)
  var isCondensed: Bool = false

  /// Tint color for the current value indicator
  var tintColor: Color = .accentColor

  private let chartHeight: CGFloat = 8
  private let indicatorSize: CGFloat = 12

  var body: some View {
    GeometryReader { geometry in
      let width = geometry.size.width

      ZStack(alignment: .leading) {
        // Background track
        Capsule()
          .fill(Color(.systemGray5))
          .frame(height: chartHeight)

        // 7-day range bar
        if rangeData.rangeSpan > 0 {
          rangeBar(width: width)
        }

        // Baseline marker (dashed line)
        if let baselinePosition = rangeData.normalizedBaselinePosition {
          baselineMarker(at: baselinePosition, width: width)
        }

        // Current value indicator
        currentValueIndicator(width: width)
      }
    }
    .frame(height: isCondensed ? 16 : 20)
  }
}

// MARK: - Components

private extension MetricRangeChart {

  func rangeBar(width: CGFloat) -> some View {
    let startX = indicatorSize / 2
    let endX = width - indicatorSize / 2
    let barWidth = endX - startX

    return Capsule()
      .fill(Color(.systemGray4))
      .frame(width: barWidth, height: chartHeight)
      .offset(x: startX)
  }

  func baselineMarker(at position: Double, width: CGFloat) -> some View {
    let clampedPosition = min(max(position, 0), 1)
    let startX = indicatorSize / 2
    let endX = width - indicatorSize / 2
    let barWidth = endX - startX
    let xOffset = startX + barWidth * clampedPosition

    return Rectangle()
      .fill(Color(.systemGray2))
      .frame(width: 2, height: chartHeight + 6)
      .offset(x: xOffset - 1)
  }

  func currentValueIndicator(width: CGFloat) -> some View {
    let startX = indicatorSize / 2
    let endX = width - indicatorSize / 2
    let barWidth = endX - startX
    let clampedPosition = min(max(rangeData.normalizedPosition, 0), 1)
    let xOffset = barWidth * clampedPosition

    return Circle()
      .fill(tintColor)
      .frame(width: indicatorSize, height: indicatorSize)
      .shadow(color: tintColor.opacity(0.3), radius: 2, x: 0, y: 1)
      .offset(x: xOffset)
  }
}

// MARK: - Preview

#Preview {
  PreviewEnvironment {
    VStack(spacing: 24) {
      // Normal range - value in middle
      VStack(alignment: .leading) {
        Text("Resting Heart Rate (62 bpm)")
          .font(.caption)
        MetricRangeChart(
          rangeData: MetricRangeData(
            metricType: "restingHeartRate",
            displayName: "Resting Heart Rate",
            currentValue: 62,
            min7Day: 55,
            max7Day: 68,
            baseline28Day: 60,
            zScore: 0.5
          ),
          tintColor: .green
        )
      }

      // Value at low end
      VStack(alignment: .leading) {
        Text("HRV (28 ms - low)")
          .font(.caption)
        MetricRangeChart(
          rangeData: MetricRangeData(
            metricType: "heartRateVariability",
            displayName: "Heart Rate Variability",
            currentValue: 28,
            min7Day: 28,
            max7Day: 52,
            baseline28Day: 42,
            zScore: -1.5
          ),
          tintColor: .orange
        )
      }

      // Value at high end
      VStack(alignment: .leading) {
        Text("Active Energy (high)")
          .font(.caption)
        MetricRangeChart(
          rangeData: MetricRangeData(
            metricType: "activeEnergy",
            displayName: "Active Energy",
            currentValue: 650,
            min7Day: 320,
            max7Day: 650,
            baseline28Day: 450,
            zScore: 1.8
          ),
          tintColor: .red
        )
      }

      // No baseline
      VStack(alignment: .leading) {
        Text("No baseline available")
          .font(.caption)
        MetricRangeChart(
          rangeData: MetricRangeData(
            metricType: "sleepDuration",
            displayName: "Sleep Duration",
            currentValue: 420,
            min7Day: 380,
            max7Day: 480,
            baseline28Day: nil,
            zScore: nil
          ),
          tintColor: .purple
        )
      }

      // Condensed version
      VStack(alignment: .leading) {
        Text("Condensed")
          .font(.caption)
        MetricRangeChart(
          rangeData: MetricRangeData(
            metricType: "restingHeartRate",
            displayName: "Resting Heart Rate",
            currentValue: 62,
            min7Day: 55,
            max7Day: 68,
            baseline28Day: 60,
            zScore: 0.5
          ),
          isCondensed: true,
          tintColor: .blue
        )
      }
    }
    .padding()
  }
}
