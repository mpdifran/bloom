//
//  SleepStageChartView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-11.
//

import SwiftUI
import Charts
import HealthKit

@MainActor
struct SleepStageChartView: View {
    let sleepAnalysis: SleepAnalysis

    @State private var samples = [HKCategorySample]()

    var body: some View {
        chartView
            .frame(height: 250)
            .task {
                do {
                    self.samples = try await HealthManager.shared.fetchSleepSamples(
                        startDate: sleepAnalysis.startDate,
                        endDate: sleepAnalysis.endDate
                    ) as? [HKCategorySample] ?? []
                } catch {
                    print(error)
                }
            }
    }
}

private extension SleepStageChartView {

    var chartView: some View {
        Chart {
            ForEach(samples, id: \.hashValue) { sample in
                if let category = sample.sleepCategory {
                    BarMark(
                        xStart: .value("Start Date", sample.startDate, unit: .second),
                        xEnd: .value("End Date", sample.endDate, unit: .second),
                        y: .value("Sleep Stage", category.name)
                    )
                    .foregroundStyle(by: .value("Sleep Stage", category.name))
                    .cornerRadius(3)
                }

            }
        }
        .chartForegroundStyleScale([
            "Deep Sleep": .deepSleep,
            "Core Sleep": .coreSleep,
            "REM Sleep": .remSleep,
            "Awake": .awakeSleep
        ])
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
