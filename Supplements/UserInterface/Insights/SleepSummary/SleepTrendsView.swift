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
                    SleepTrendChart(
                        title: "Deep Sleep",
                        sleepAnalyses: viewModel.sleepAnalyses,
                        keyPath: \.deepSleepPercent,
                        color: .deepSleep
                    )
                    .frame(height: 150)
                }
            }

            Section {
                VStack(alignment: .leading) {
                    SleepTrendChart(
                        title: "Core Sleep",
                        sleepAnalyses: viewModel.sleepAnalyses,
                        keyPath: \.coreSleepPercent,
                        color: .coreSleep
                    )
                    .frame(height: 150)
                }
            }

            Section {
                VStack(alignment: .leading) {
                    SleepTrendChart(
                        title: "REM Sleep",
                        sleepAnalyses: viewModel.sleepAnalyses,
                        keyPath: \.remSleepPercent,
                        color: .remSleep
                    )
                    .frame(height: 150)
                }
            }

            Section {
                VStack(alignment: .leading) {
                    SleepTrendChart(
                        title: "Sleep Length",
                        sleepAnalyses: viewModel.sleepAnalyses,
                        keyPath: \.overallHours,
                        color: .green,
                        yAxisLabel: .nominal("hours")
                    )
                    .frame(height: 150)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Sleep Trends")
        .task {
            await viewModel.loadSleepAnalysis()
        }
    }
}

#Preview {
    SleepTrendsView()
}
