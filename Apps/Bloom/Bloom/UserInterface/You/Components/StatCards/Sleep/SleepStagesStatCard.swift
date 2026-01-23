//
//  SleepStagesStatCard.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-29.
//

import SwiftUI
import Charts
import CoreHealth

struct SleepStagesStatCard: View {
  let sleepStageDataPoints: [SleepStageDataPoint]?

  var body: some View {
    StatCard(
      symbol: .moonZzzFill,
      title: "Sleep Stages",
      value: hasData ? nil : "No Data",
      valueStyle: .largeTinted(nil),
      aspectRatio: 2,
      layerContent: hasData,
      includePadding: !hasData
    ) {
      sleepStagesChart
    }
    .tint(sleepStageDataPoints == nil ? AnyShapeStyle(.gray) : AnyShapeStyle(.coreSleep))
  }
}

private extension SleepStagesStatCard {

  var hasData: Bool {
    sleepStageDataPoints?.isNotEmpty ?? false
  }

  @ViewBuilder
  var sleepStagesChart: some View {
    if let dataPoints = sleepStageDataPoints, dataPoints.isNotEmpty {
      Chart(dataPoints) { dataPoint in
        AreaMark(
          x: .value("Day", dataPoint.date),
          y: .value("Minutes", dataPoint.minutes),
          stacking: .standard
        )
        .foregroundStyle(by: .value("Stage", dataPoint.stage.rawValue))
        .interpolationMethod(.catmullRom)
      }
      .chartForegroundStyleScale([
        CoreHealth.SleepStage.core.rawValue: Color.coreSleep,
        CoreHealth.SleepStage.deep.rawValue: Color.deepSleep,
        CoreHealth.SleepStage.rem.rawValue: Color.remSleep,
        CoreHealth.SleepStage.awake.rawValue: Color.awakeSleep
      ])
      .chartXAxis(.hidden)
      .chartYAxis(.hidden)
      .chartLegend(.hidden)
      .chartXScale(domain: chartXDomain)
    }
  }

  var chartXDomain: ClosedRange<Date> {
    guard let dataPoints = sleepStageDataPoints,
          let minDate = dataPoints.map(\.date).min(),
          let maxDate = dataPoints.map(\.date).max() else {
      return Date()...Date()
    }
    return minDate...maxDate
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      VStack(spacing: 8) {
        SleepStagesStatCard(sleepStageDataPoints: previewSleepStageData)
        SleepStagesStatCard(sleepStageDataPoints: nil)
      }
    }
  }
}

private let previewSleepStageData: [SleepStageDataPoint] = {
  let calendar = Calendar.current
  return (0..<7).reversed().flatMap { daysAgo -> [SleepStageDataPoint] in
    let date = calendar.startOfDay(for: Date().addingTimeInterval(Double(-daysAgo) * 86400))
    return [
      SleepStageDataPoint(date: date, stage: .deep, minutes: Double.random(in: 40...80)),
      SleepStageDataPoint(date: date, stage: .core, minutes: Double.random(in: 200...300)),
      SleepStageDataPoint(date: date, stage: .rem, minutes: Double.random(in: 60...120)),
      SleepStageDataPoint(date: date, stage: .awake, minutes: Double.random(in: 10...40))
    ]
  }
}()
