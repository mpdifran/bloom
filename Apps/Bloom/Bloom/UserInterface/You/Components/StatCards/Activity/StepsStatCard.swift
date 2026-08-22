//
//  StepsStatCard.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-30.
//

import SwiftUI
import Charts

struct StepsStatCard: View {
  let chartData: WeeklyStepsChartData?

  var body: some View {
    StatCard(
      symbol: .figureWalk,
      title: "Steps",
      value: hasData ? nil : "No Data",
      valueStyle: .largeTinted(nil),
      aspectRatio: 2,
      layerContent: hasData,
      includePadding: !hasData
    ) {
      stepsChart
    }
    .tint(chartData == nil ? AnyShapeStyle(.gray) : AnyShapeStyle(.mutedYellow))
  }
}

private extension StepsStatCard {

  var hasData: Bool {
    chartData?.thisWeekDataPoints.isNotEmpty ?? false
  }

  @ViewBuilder
  var stepsChart: some View {
    if let chartData, chartData.thisWeekDataPoints.isNotEmpty {
      ZStack {
        Chart {
          // Last week line (faded)
          ForEach(chartData.lastWeekDataPoints) { dataPoint in
            LineMark(
              x: .value("Time", dataPoint.index),
              y: .value("Steps", dataPoint.cumulativeSteps),
              series: .value("Week", dataPoint.series)
            )
            .foregroundStyle(Color.mutedYellow.opacity(0.3))
            .lineStyle(StrokeStyle(lineWidth: 4))
            .interpolationMethod(.catmullRom)
          }

          // This week line (solid)
          ForEach(chartData.thisWeekDataPoints) { dataPoint in
            LineMark(
              x: .value("Time", dataPoint.index),
              y: .value("Steps", dataPoint.cumulativeSteps),
              series: .value("Week", dataPoint.series)
            )
            .foregroundStyle(Color.mutedYellow)
            .lineStyle(StrokeStyle(lineWidth: 4))
            .interpolationMethod(.catmullRom)
          }

          // Current point mark with border
          if let currentPoint = chartData.thisWeekDataPoints.last {
            // Border (larger, background color)
            PointMark(
              x: .value("Time", currentPoint.index),
              y: .value("Steps", currentPoint.cumulativeSteps)
            )
            .foregroundStyle(Color(.systemBackground))
            .symbolSize(100)

            // Inner fill
            PointMark(
              x: .value("Time", currentPoint.index),
              y: .value("Steps", currentPoint.cumulativeSteps)
            )
            .foregroundStyle(Color.mutedYellow)
            .symbolSize(40)
          }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .animation(.default, value: chartData.totalStepsThisWeek)

        statsOverlay
          .zStackAlignment(.bottomTrailing)
          .animation(.default, value: chartData.totalStepsThisWeek)
      }
    }
  }

  var statsOverlay: some View {
    VStack(alignment: .trailing, spacing: 2) {
      if let chartData {
        Text(formattedSteps(chartData.totalStepsThisWeek))
          .font(.title2)
          .bold()
          .fontDesign(.rounded)
          .foregroundStyle(.mutedYellow)
          .contentTransition(.numericText(value: Double(chartData.totalStepsThisWeek)))

        if let percentChange = chartData.percentageChangeFromLastWeek {
          Text(formattedPercentChange(percentChange))
            .font(.caption)
            .bold()
            .fontDesign(.rounded)
            .foregroundStyle(.secondary)
            .contentTransition(.numericText(value: Double(percentChange)))
        }
      }
    }
    .padding()
  }

  func formattedSteps(_ steps: Int) -> String {
    steps.formatted()
  }

  func formattedPercentChange(_ change: Double) -> String {
    let sign = change >= 0 ? "+" : ""
    let percent = "\(sign)\(Int(change))%"
    return String(localized: "\(percent) vs last week", comment: "Steps card comparison. The placeholder is a signed percentage change, e.g. \"+12%\".")
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      VStack(spacing: 8) {
        StepsStatCard(chartData: previewStepsData)
        StepsStatCard(chartData: nil)
      }
    }
  }
}

private let previewStepsData: WeeklyStepsChartData = {
  // This week (partial - up to current 4-hour window)
  // 6 windows per day × ~3.5 days = ~21 data points
  let thisWeekPoints = (0..<21).map { index in
    StepsDataPoint(
      date: Date(),
      cumulativeSteps: (index + 1) * 1500,
      index: index,
      series: "This Week"
    )
  }

  // Last week (full week) - 6 windows per day × 7 days = 42 data points
  let lastWeekPoints = (0..<42).map { index in
    StepsDataPoint(
      date: Date(),
      cumulativeSteps: (index + 1) * 1250,
      index: index,
      series: "Last Week"
    )
  }

  return WeeklyStepsChartData(
    thisWeekDataPoints: thisWeekPoints,
    lastWeekDataPoints: lastWeekPoints,
    totalStepsThisWeek: 31500,
    percentageChangeFromLastWeek: 12.5
  )
}()
