//
//  SleepTrendsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-30.
//

import SwiftUI

@MainActor
struct SleepTrendsView: View {
    @ObservedObject private var viewModel = SleepTrendsViewModel()

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading) {
                    ChartTitleView("Deep Sleep %")
                    SleepTrendChart(
                        sleepAnalyses: viewModel.sleepAnalyses,
                        keyPath: \.deepSleepPercent,
                        color: .deepSleep,
                        yAxisLabel: .percent
                    )
                    .frame(height: 300)
                }
            }

            Section {
                VStack(alignment: .leading) {
                    ChartTitleView("REM Sleep %")
                    SleepTrendChart(
                        sleepAnalyses: viewModel.sleepAnalyses,
                        keyPath: \.remSleepPercent,
                        color: .remSleep,
                        yAxisLabel: .percent
                    )
                    .frame(height: 300)
                }
            }

            Section {
                VStack(alignment: .leading) {
                    ChartTitleView("Sleep Length")
                    SleepTrendChart(
                        sleepAnalyses: viewModel.sleepAnalyses,
                        keyPath: \.overallHours,
                        color: .green
                    )
                    .frame(height: 300)
                }
            }
        }
        .navigationTitle("Sleep Trends")
        .task {
            await viewModel.loadSleepAnalysis()
        }
    }
}

#Preview {
    SleepTrendsView()
}
