//
//  MonitorSummaryBar.swift
//  Bloom
//

import SwiftUI
import DataContainer
import BloomFoundation

/// A horizontal bar showing z-score zones with 7-day range and current metric positions.
/// Displays three zones: Low (z < -1), Normal (-1 to 1), and High (z > 1).
struct MonitorSummaryBar: View {

  let data: MonitorSummaryBarData
  var showsLabels: Bool = true
  var lowLabel: String = "Low"
  var normalLabel: String = "Typical"
  var highLabel: String = "High"

  // Layout constants
  private let barHeight: CGFloat = 20
  private let dotSize: CGFloat = 12

  // Z-score boundaries
  private let lowThreshold: Double = -1.0
  private let highThreshold: Double = 1.0
  private let displayRange: Double = 3.0 // Display from -3 to +3

  var body: some View {
    VStack(spacing: 4) {
      GeometryReader { geometry in
        let width = geometry.size.width

        ZStack {
          // Background zones (Low | Normal | High)
          zoneBackground(width: width)

          // 7-day range bar overlay
          rangeBar(width: width)

          // Current value dots for each metric
          metricDots(width: width)
        }
      }
      .frame(height: barHeight)

      // Zone labels
      if showsLabels {
        zoneLabels
      }
    }
  }
}

// MARK: - Helper Types

private extension MonitorSummaryBar {

  /// A dot position with preserved metric identity
  struct DotPosition: Identifiable {
    let id: String  // metricType
    let xPosition: CGFloat
  }

  /// A group of close dots with stable identity
  struct DotGroup: Identifiable {
    let id: String  // first metric's ID
    let positions: [DotPosition]
    var minX: CGFloat { positions.map(\.xPosition).min()! }
    var maxX: CGFloat { positions.map(\.xPosition).max()! }
  }
}

// MARK: - Components

private extension MonitorSummaryBar {

  /// Background showing the three z-score zones
  func zoneBackground(width: CGFloat) -> some View {
    HStack(spacing: 0) {
      // Low zone (left third: z < -1)
      Rectangle()
        .fill(Color(.systemGray5))
        .frame(width: width / 3)

      // Normal zone (middle third: -1 to 1)
      Rectangle()
        .fill(Color(.systemGray6))
        .frame(width: width / 3)

      // High zone (right third: z > 1)
      Rectangle()
        .fill(Color(.systemGray5))
        .frame(width: width / 3)
    }
    .frame(height: barHeight)
    .clipShape(Capsule())
  }

  /// The colored bar showing 7-day z-score range
  func rangeBar(width: CGFloat) -> some View {
    let startPosition = normalizedPosition(for: data.min7DayZScore)
    let endPosition = normalizedPosition(for: data.max7DayZScore)
    let barWidth = width * (endPosition - startPosition)
    // Offset from center
    let xOffset = width * startPosition + barWidth / 2 - width / 2

    return Capsule()
      .fill(rangeBarGradient(startPos: startPosition, endPos: endPosition))
      .frame(width: max(barWidth, 4), height: barHeight - 2)
      .offset(x: xOffset)
  }

  /// Creates a gradient for the range bar based on which zones it crosses
  func rangeBarGradient(startPos: Double, endPos: Double) -> LinearGradient {
    let barSpan = endPos - startPos
    guard barSpan > 0.001 else {
      // Single point - return solid color based on zone
      return LinearGradient(
        colors: [colorForPosition(startPos)],
        startPoint: .leading,
        endPoint: .trailing
      )
    }

    // Zone boundaries in global (0-1) space
    let lowBoundary = normalizedPosition(for: lowThreshold)   // ~0.333
    let highBoundary = normalizedPosition(for: highThreshold) // ~0.667

    // Convert global position to bar-local space (0-1 within the bar)
    func toLocalSpace(_ globalPos: Double) -> Double {
      max(0, min(1, (globalPos - startPos) / barSpan))
    }

    // Gradient transition width (how much space for color blending)
    let transitionWidth = 0.30

    var stops: [Gradient.Stop] = []

    // Start color based on starting zone
    let startColor = colorForPosition(startPos)
    stops.append(Gradient.Stop(color: startColor, location: 0))

    // Add smooth transition at low boundary if bar crosses it
    if startPos < lowBoundary && endPos > lowBoundary {
      let localPos = toLocalSpace(lowBoundary)
      let transitionStart = max(0, localPos - transitionWidth / 2)
      let transitionEnd = min(1, localPos + transitionWidth / 2)
      stops.append(Gradient.Stop(color: .monitorLow, location: transitionStart))
      stops.append(Gradient.Stop(color: .monitorTypical, location: transitionEnd))
    }

    // Add smooth transition at high boundary if bar crosses it
    if startPos < highBoundary && endPos > highBoundary {
      let localPos = toLocalSpace(highBoundary)
      let transitionStart = max(0, localPos - transitionWidth / 2)
      let transitionEnd = min(1, localPos + transitionWidth / 2)
      stops.append(Gradient.Stop(color: .monitorTypical, location: transitionStart))
      stops.append(Gradient.Stop(color: .monitorHigh, location: transitionEnd))
    }

    // End color based on ending zone
    let endColor = colorForPosition(endPos)
    stops.append(Gradient.Stop(color: endColor, location: 1))

    return LinearGradient(stops: stops, startPoint: .leading, endPoint: .trailing)
  }

  /// Returns the color for a given normalized position based on which zone it falls in
  func colorForPosition(_ position: Double) -> Color {
    let lowBoundary = normalizedPosition(for: lowThreshold)
    let highBoundary = normalizedPosition(for: highThreshold)

    if position < lowBoundary {
      return .monitorLow
    } else if position < highBoundary {
      return .monitorTypical
    } else {
      return .monitorHigh
    }
  }

  /// Individual dots for each metric's current z-score
  /// Dots that are close together merge into a capsule shape
  func metricDots(width: CGFloat) -> some View {
    let startPosition = normalizedPosition(for: data.min7DayZScore)
    let endPosition = normalizedPosition(for: data.max7DayZScore)

    // Horizontal inset matches vertical inset: (barHeight - 2 - dotSize) / 2
    let inset = (barHeight - 2 - dotSize) / 2

    // Min/max x positions for dot centers
    let barStartX = width * startPosition
    let barEndX = width * endPosition
    let minDotCenterX = barStartX + inset + dotSize / 2
    let maxDotCenterX = barEndX - inset - dotSize / 2

    // Calculate positions preserving identity
    let dotPositions: [DotPosition] = data.metricZScores.map { point in
      let position = normalizedPosition(for: point.zScore)
      let rawX = width * position
      let clampedX = min(max(rawX, minDotCenterX), maxDotCenterX)
      return DotPosition(id: point.metricType, xPosition: clampedX)
    }.sorted { $0.xPosition < $1.xPosition }

    // Group close positions while preserving identity
    let groups = groupClosePositions(dotPositions, threshold: dotSize * 4)

    return ForEach(groups) { group in
      if group.positions.count == 1 {
        // Single dot - draw circle
        let xOffset = group.positions[0].xPosition - width / 2
        Circle()
          .fill(Color.black)
          .frame(width: dotSize, height: dotSize)
          .offset(x: xOffset)
          .animation(.easeInOut(duration: 0.3), value: xOffset)
      } else {
        // Multiple close dots - draw capsule spanning from first to last
        let capsuleWidth = group.maxX - group.minX + dotSize
        let centerX = (group.minX + group.maxX) / 2
        let xOffset = centerX - width / 2
        Capsule()
          .fill(Color.black)
          .frame(width: capsuleWidth, height: dotSize)
          .offset(x: xOffset)
          .animation(.easeInOut(duration: 0.3), value: xOffset)
          .animation(.easeInOut(duration: 0.3), value: capsuleWidth)
      }
    }
  }

  /// Groups sorted positions that are within threshold distance of each other
  func groupClosePositions(_ positions: [DotPosition], threshold: CGFloat) -> [DotGroup] {
    guard !positions.isEmpty else { return [] }

    var groups: [DotGroup] = []
    var currentGroup: [DotPosition] = [positions[0]]

    for i in 1..<positions.count {
      if positions[i].xPosition - currentGroup.last!.xPosition <= threshold {
        currentGroup.append(positions[i])
      } else {
        groups.append(DotGroup(id: currentGroup[0].id, positions: currentGroup))
        currentGroup = [positions[i]]
      }
    }
    groups.append(DotGroup(id: currentGroup[0].id, positions: currentGroup))

    return groups
  }

  /// Zone labels below the bar
  var zoneLabels: some View {
    HStack {
      Text(lowLabel)
        .frame(maxWidth: .infinity)
      Text(normalLabel)
        .frame(maxWidth: .infinity)
      Text(highLabel)
        .frame(maxWidth: .infinity)
    }
    .font(.caption2)
    .foregroundStyle(.secondary)
  }

  /// Convert z-score to normalized position (0-1) within display range
  func normalizedPosition(for zScore: Double) -> Double {
    // Clamp z-score to display range (-3 to +3)
    let clamped = min(max(zScore, -displayRange), displayRange)
    // Normalize to 0-1 range
    return (clamped + displayRange) / (displayRange * 2)
  }
}

// MARK: - Preview

#Preview {
  PreviewEnvironment {
    VStack(spacing: 24) {
      // Normal range - all metrics in normal zone
      VStack(alignment: .leading) {
        Text("Recovery - Normal")
          .font(.caption)
        MonitorSummaryBar(
          data: MonitorSummaryBarData(
            metricZScores: [
              MetricZScorePoint(metricType: "restingHeartRate", zScore: 0.3),
              MetricZScorePoint(metricType: "heartRateVariability", zScore: -0.5),
              MetricZScorePoint(metricType: "respiratoryRate", zScore: 0.1)
            ],
            min7DayZScore: -0.8,
            max7DayZScore: 0.6
          )
        )
      }

      // Elevated - range crosses into high zone
      VStack(alignment: .leading) {
        Text("Stress - Elevated")
          .font(.caption)
        MonitorSummaryBar(
          data: MonitorSummaryBarData(
            metricZScores: [
              MetricZScorePoint(metricType: "activeEnergy", zScore: 1.5),
              MetricZScorePoint(metricType: "heartRateRecovery", zScore: 0.8)
            ],
            min7DayZScore: 0.2,
            max7DayZScore: 1.8
          )
        )
      }

      // Alert - range crosses into low zone
      VStack(alignment: .leading) {
        Text("Sleep - Alert (Low)")
          .font(.caption)
        MonitorSummaryBar(
          data: MonitorSummaryBarData(
            metricZScores: [
              MetricZScorePoint(metricType: "sleepDuration", zScore: -2.0),
              MetricZScorePoint(metricType: "deepSleep", zScore: -1.5),
              MetricZScorePoint(metricType: "sleepEfficiency", zScore: -0.8)
            ],
            min7DayZScore: -2.3,
            max7DayZScore: -0.5
          )
        )
      }

      // Wide range - crosses multiple zones
      VStack(alignment: .leading) {
        Text("Recovery - Wide Range")
          .font(.caption)
        MonitorSummaryBar(
          data: MonitorSummaryBarData(
            metricZScores: [
              MetricZScorePoint(metricType: "restingHeartRate", zScore: 1.8),
              MetricZScorePoint(metricType: "heartRateVariability", zScore: -1.2),
              MetricZScorePoint(metricType: "wristTemperature", zScore: 0.5)
            ],
            min7DayZScore: -1.5,
            max7DayZScore: 2.0
          )
        )
      }
    }
    .padding()
  }
}
