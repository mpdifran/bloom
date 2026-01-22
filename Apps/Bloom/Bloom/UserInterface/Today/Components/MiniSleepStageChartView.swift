//
//  MiniSleepStageChartView.swift
//  Bloom
//
//  Created by Claude on 2026-01-21.
//

import SwiftUI
import Charts
import CoreHealth
import BloomFoundation
@preconcurrency import HealthKit

@MainActor
struct MiniSleepStageChartView: View {
  let sleepAnalysis: SleepAnalysis

  @State private var samples = [HKSample]()

  var body: some View {
    chartView
      .frame(height: 180)
      .task {
        await loadSamples()
      }
      .onChange(of: sleepAnalysis) { _, _ in
        Task {
          await loadSamples()
        }
      }
  }
}

private extension MiniSleepStageChartView {

  func loadSamples() async {
    self.samples = await Task {
      (try? await HealthStoreFetcher.shared.fetchSamples(
        for: HKCategoryType(.sleepAnalysis),
        dateRange: DateRange(sleepAnalysis.startDate, sleepAnalysis.endDate)
      )) ?? []
    }.value
  }
}

private extension MiniSleepStageChartView {

  var chartView: some View {
    Chart {
      ForEach(samples, id: \.hashValue) { sample in
        if
          let categorySample = sample as? HKCategorySample,
          let category = categorySample.sleepCategory,
          category != .inBed && category != .asleepUnspecified
        {
          BarMark(
            xStart: .value("Start Date", sample.startDate, unit: .second),
            xEnd: .value("End Date", sample.endDate, unit: .second),
            y: .value("Sleep Stage", category.name)
          )
          .foregroundStyle(by: .value("Sleep Stage", category.name))
          .cornerRadius(4)
        }
      }
    }
    .chartForegroundStyleScale([
      "Awake": .awakeSleep,
      "REM Sleep": .remSleep,
      "Core Sleep": .coreSleep,
      "Deep Sleep": .deepSleep
    ])
    .chartYAxis(.hidden)
    .chartXAxis(.hidden)
    .chartLegend(.hidden)
    .chartYScale(domain: ["Awake", "REM Sleep", "Core Sleep", "Deep Sleep"])
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      MiniSleepStageChartView(sleepAnalysis: SleepAnalysis.previewData[0])
        .cardContainer()
    }
  }
}
