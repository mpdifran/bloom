//
//  SleepStageChartView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-11.
//

import SFSafeSymbols
import SwiftUI
import Charts
import BloomFoundation
import CoreHealth
@preconcurrency import HealthKit

@MainActor
struct SleepStageChartView: View {
  let sleepAnalysis: SleepAnalysis

  @State private var samples = [HKSample]()

  var body: some View {
    VStack {
      chartView
        .frame(height: 250)
    }
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

private extension SleepStageChartView {

  func loadSamples() async {
    self.samples = await Task {
      (try? await HealthStoreFetcher.shared.fetchSamples(
        for: HKCategoryType(.sleepAnalysis),
        dateRange: DateRange(sleepAnalysis.startDate, sleepAnalysis.endDate)
      )) ?? []
    }.value
  }
}

private extension SleepStageChartView {

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
          .cornerRadius(10)
        }
      }
    }
    .chartForegroundStyleScale([
      "Awake": .awakeSleep,
      "REM Sleep": .remSleep,
      "Core Sleep": .coreSleep,
      "Deep Sleep": .deepSleep
    ])
    .chartYAxis {
      AxisMarks(values: ["Awake", "REM Sleep", "Core Sleep", "Deep Sleep"]) {
        AxisGridLine()
        AxisTick()
      }
    }
    .chartYScale(domain: ["Awake", "REM Sleep", "Core Sleep", "Deep Sleep"])
    .chartXAxis {
      AxisMarks(values: .stride(by: .hour)) { value in
        AxisGridLine()
        AxisTick()
        AxisValueLabel(format: .dateTime.hour())
      }
    }
  }
}

#Preview {
  List {
    SleepStageChartView(sleepAnalysis: SleepAnalysis.previewData[0])
  }
  .listStyle(.plain)
}
