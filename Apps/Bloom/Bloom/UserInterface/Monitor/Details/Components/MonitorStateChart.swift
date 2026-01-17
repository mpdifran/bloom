//
//  MonitorStateChart.swift
//  Bloom
//
//  Created by Claude on 2026-01-10.
//

import SwiftUI
import Charts
import DataContainer
import CoreHealth

/// A chart displaying monitor signal z-score ranges over time.
/// Shows vertical bars from min to max z-score for each day, with gradient coloring.
struct MonitorStateChart: View {

  let monitorType: MonitorType
  let days: Int

  @State private var dayRanges: [DayZScoreRange] = []

  // Z-score boundaries (same as MonitorSummaryBar)
  private let lowThreshold: Double = -1.0
  private let highThreshold: Double = 1.0
  private let displayRange: Double = 3.0

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Signal History")
        .font(.headline)

      if dayRanges.isEmpty {
        emptyChart
      } else {
        chartWithBackground
          .transition(.opacity)
      }
    }
    .animation(.easeInOut(duration: 0.3), value: dayRanges.map(\.id))
    .task(id: days) {
      await loadData()
    }
  }

  // MARK: - Data Loading

  private func loadData() async {
    if monitorType == .stress {
      await loadStressData()
    } else {
      do {
        let actor = DailyMetricSampleModelActor.standard()
        let metricTypes = monitorType.metrics.map { $0.rawValue }
        dayRanges = try await actor.fetchDailyZScoreRanges(metricTypes: metricTypes, days: days)
      } catch {
        dayRanges = []
      }
    }
  }

  private func loadStressData() async {
    let calendar = Calendar.current

    // 1. Load burnout metrics from DailyMetricSample (HRV, sleep efficiency, etc.)
    let actor = DailyMetricSampleModelActor.standard()
    let metricTypes = MonitorType.stress.detectionMetrics.map { $0.rawValue }
    let metricRanges = (try? await actor.fetchDailyZScoreRanges(metricTypes: metricTypes, days: days)) ?? []

    // 2. Load training load z-scores
    await TrainingLoadCalculator.shared.refreshTrainingLoad()
    guard let summary = await TrainingLoadCalculator.shared.trainingLoadSummary else {
      // No training load - just use metric ranges
      dayRanges = metricRanges
      return
    }

    // 3. Calculate training load z-scores per day
    var trainingLoadByDate: [Date: Double] = [:]
    let trendCount = summary.sevenDayTrend.count
    let startIndex = max(0, trendCount - days)

    for index in startIndex..<trendCount {
      let sevenDayPoint = summary.sevenDayTrend[index]
      let twentyEightDayValue = index < summary.twentyEightDayTrend.count
        ? summary.twentyEightDayTrend[index].value
        : 0

      let zScore: Double
      if twentyEightDayValue > 0 {
        let percentDiff = ((sevenDayPoint.value - twentyEightDayValue) / twentyEightDayValue) * 100
        zScore = percentDiff / 10.0
      } else {
        zScore = 0
      }

      let dayStart = calendar.startOfDay(for: sevenDayPoint.date)
      trainingLoadByDate[dayStart] = zScore
    }

    // 4. Merge training load with metric ranges
    var mergedRanges: [Date: (min: Double, max: Double)] = [:]

    // Add metric ranges
    for range in metricRanges {
      let dayStart = calendar.startOfDay(for: range.date)
      mergedRanges[dayStart] = (range.minZScore, range.maxZScore)
    }

    // Merge in training load z-scores
    for (date, zScore) in trainingLoadByDate {
      if let existing = mergedRanges[date] {
        mergedRanges[date] = (min(existing.min, zScore), max(existing.max, zScore))
      } else {
        mergedRanges[date] = (zScore, zScore)
      }
    }

    // 5. Convert to DayZScoreRange array
    dayRanges = mergedRanges.map { date, range in
      DayZScoreRange(date: date, minZScore: range.min, maxZScore: range.max)
    }.sorted { $0.date < $1.date }
  }

  // MARK: - Chart

  private var chartWithBackground: some View {
    chart
      .chartBackground { proxy in
        GeometryReader { geometry in
          zoneBackground(proxy: proxy, geometry: geometry)
        }
      }
  }

  private var chart: some View {
    Chart(dayRanges) { range in
      let (adjustedMin, adjustedMax) = adjustedRange(for: range)
      BarMark(
        x: .value("Date", range.date, unit: .day),
        yStart: .value("Min", adjustedMin),
        yEnd: .value("Max", adjustedMax),
        width: barWidth
      )
      .foregroundStyle(gradientForRange(min: range.minZScore, max: range.maxZScore))
      .clipShape(Capsule())
    }
    .chartYScale(domain: -displayRange...displayRange)
    .chartYAxis {
      // Grid lines at zone boundaries
      AxisMarks(values: [lowThreshold, highThreshold]) { _ in
        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
          .foregroundStyle(Color(.systemGray4))
      }
      // Labels at zone centers
      AxisMarks(values: [-2, 0, 2]) { value in
        if let doubleValue = value.as(Double.self) {
          AxisValueLabel {
            Text(labelForValue(doubleValue))
              .font(.caption2)
              .foregroundStyle(.secondary)
          }
        }
      }
    }
    .chartXAxis {
      AxisMarks(values: .stride(by: .day, count: xAxisStride)) { _ in
        AxisValueLabel(format: days > 7 ? .dateTime.day() : .dateTime.weekday(.abbreviated))
        AxisGridLine()
      }
    }
    .frame(height: 120)
  }

  private func labelForValue(_ value: Double) -> String {
    if value == -2 {
      return "Low"
    } else if value == 0 {
      return "Typical"
    } else if value == 2 {
      return "High"
    }
    return ""
  }

  private var xAxisStride: Int {
    // Show fewer labels for longer periods
    days > 14 ? 7 : 1
  }

  /// Clamps z-score range to display range and ensures minimum visible bar height
  private func adjustedRange(for range: DayZScoreRange) -> (min: Double, max: Double) {
    let clampedMin = max(-displayRange, min(displayRange, range.minZScore))
    let clampedMax = max(-displayRange, min(displayRange, range.maxZScore))

    // Ensure minimum visible bar height after clamping
    let minVisibleHeight = 0.15
    if clampedMax - clampedMin < minVisibleHeight * 2 {
      let center = (clampedMin + clampedMax) / 2
      return (
        max(-displayRange, center - minVisibleHeight),
        min(displayRange, center + minVisibleHeight)
      )
    }
    return (clampedMin, clampedMax)
  }

  private var barWidth: MarkDimension {
    days <= 7 ? .fixed(10) : .automatic
  }

  // MARK: - Zone Background

  private func zoneBackground(proxy: ChartProxy, geometry: GeometryProxy) -> some View {
    let plotArea = geometry[proxy.plotFrame!]

    // Calculate y positions for zone boundaries
    let yLow = proxy.position(forY: lowThreshold) ?? 0
    let yHigh = proxy.position(forY: highThreshold) ?? 0
    let yTop = proxy.position(forY: displayRange) ?? 0
    let yBottom = proxy.position(forY: -displayRange) ?? plotArea.height

    return ZStack {
      // High zone (top)
      Rectangle()
        .fill(Color(.systemGray5).opacity(0.5))
        .frame(width: plotArea.width, height: yHigh - yTop)
        .position(x: plotArea.midX, y: yTop + (yHigh - yTop) / 2)

      // Typical zone (middle)
      Rectangle()
        .fill(Color(.systemGray6).opacity(0.5))
        .frame(width: plotArea.width, height: yLow - yHigh)
        .position(x: plotArea.midX, y: yHigh + (yLow - yHigh) / 2)

      // Low zone (bottom)
      Rectangle()
        .fill(Color(.systemGray5).opacity(0.5))
        .frame(width: plotArea.width, height: yBottom - yLow)
        .position(x: plotArea.midX, y: yLow + (yBottom - yLow) / 2)
    }
  }

  // MARK: - Gradient

  /// Creates a vertical gradient for the bar based on which zones it crosses
  private func gradientForRange(min: Double, max: Double) -> LinearGradient {
    let normalizedMin = normalizedPosition(for: min)
    let normalizedMax = normalizedPosition(for: max)
    let barSpan = normalizedMax - normalizedMin

    guard barSpan > 0.001 else {
      // Single point - return solid color based on zone
      return LinearGradient(
        colors: [colorForZScore(min)],
        startPoint: .bottom,
        endPoint: .top
      )
    }

    // Zone boundaries in normalized (0-1) space
    let lowBoundary = normalizedPosition(for: lowThreshold)   // ~0.333
    let highBoundary = normalizedPosition(for: highThreshold) // ~0.667

    // Convert global position to bar-local space (0-1 within the bar)
    func toLocalSpace(_ globalPos: Double) -> Double {
      Swift.max(0, Swift.min(1, (globalPos - normalizedMin) / barSpan))
    }

    // Gradient transition width (how much space for color blending)
    let transitionWidth = 0.30

    var stops: [Gradient.Stop] = []

    // Start color based on starting zone (bottom of bar)
    let startColor = colorForZScore(min)
    stops.append(Gradient.Stop(color: startColor, location: 0))

    // Add smooth transition at low boundary if bar crosses it
    if normalizedMin < lowBoundary && normalizedMax > lowBoundary {
      let localPos = toLocalSpace(lowBoundary)
      let transitionStart = Swift.max(0, localPos - transitionWidth / 2)
      let transitionEnd = Swift.min(1, localPos + transitionWidth / 2)
      stops.append(Gradient.Stop(color: .monitorLow, location: transitionStart))
      stops.append(Gradient.Stop(color: .monitorTypical, location: transitionEnd))
    }

    // Add smooth transition at high boundary if bar crosses it
    if normalizedMin < highBoundary && normalizedMax > highBoundary {
      let localPos = toLocalSpace(highBoundary)
      let transitionStart = Swift.max(0, localPos - transitionWidth / 2)
      let transitionEnd = Swift.min(1, localPos + transitionWidth / 2)
      stops.append(Gradient.Stop(color: .monitorTypical, location: transitionStart))
      stops.append(Gradient.Stop(color: .monitorHigh, location: transitionEnd))
    }

    // End color based on ending zone (top of bar)
    let endColor = colorForZScore(max)
    stops.append(Gradient.Stop(color: endColor, location: 1))

    return LinearGradient(stops: stops, startPoint: .bottom, endPoint: .top)
  }

  /// Returns the color for a given z-score based on which zone it falls in
  private func colorForZScore(_ zScore: Double) -> Color {
    if zScore < lowThreshold {
      return .monitorLow
    } else if zScore < highThreshold {
      return .monitorTypical
    } else {
      return .monitorHigh
    }
  }

  /// Convert z-score to normalized position (0-1) within display range
  private func normalizedPosition(for zScore: Double) -> Double {
    let clamped = Swift.min(Swift.max(zScore, -displayRange), displayRange)
    return (clamped + displayRange) / (displayRange * 2)
  }

  // MARK: - Empty State

  private var emptyChart: some View {
    RoundedRectangle(cornerRadius: 8)
      .fill(Color(.systemGray6))
      .frame(height: 120)
      .overlay {
        Text("No signal history available")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
  }
}

// MARK: - Preview

#Preview {
  PreviewEnvironment {
    VStack(spacing: 32) {
      MonitorStateChart(monitorType: .recovery, days: 7)
        .cardContainer()

      MonitorStateChart(monitorType: .stress, days: 30)
        .cardContainer()
    }
    .padding()
  }
}
