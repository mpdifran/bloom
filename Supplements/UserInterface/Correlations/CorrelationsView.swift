//
//  CorrelationsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-29.
//

import SwiftUI

struct CorrelationsView: View {
    @ObservedObject private var viewModel = CorrelationsViewModel.shared

    var body: some View {
        NavigationStack {
            List {
                if let data = viewModel.timeInDaylightSleepLengthCorrelationData {
                    Section {
                        CorrelationChartCell(
                            title: "Time in Daylight vs Sleep Length",
                            dataSet: data.0.suffix(30),
                            correlationCoefficient: data.1,
                            aConfig: .init(title: "Time in Daylight", color: .orange, unit: "h"),
                            bConfig: .init(title: "Sleep Length", color: .coreSleep, unit: "h")
                        )
                    }
                }
                if let data = viewModel.activeEnergySleepLengthCorrelationData {
                    Section {
                        CorrelationChartCell(
                            title: "Active Energy vs Sleep Length",
                            dataSet: data.0.suffix(30),
                            correlationCoefficient: data.1,
                            aConfig: .init(title: "Active Energy", color: .green, unit: "Cal"),
                            bConfig: .init(title: "Sleep Length", color: .coreSleep, unit: "h")
                        )
                    }
                }
                if let data = viewModel.exerciseMinutesSleepScoreCorrelationData {
                    Section {
                        CorrelationChartCell(
                            title: "Exercise Minutes vs Sleep Quality",
                            dataSet: data.0.suffix(30),
                            correlationCoefficient: data.1,
                            aConfig: .init(title: "Exercise Minutes", color: .yellow, unit: "min"),
                            bConfig: .init(title: "Sleep Quality", color: .remSleep, unit: "")
                        )
                    }
                }
            }
            .navigationTitle("Insights")
        }
        .tabItem {
            Label("Insights", systemImage: "chart.xyaxis.line")
        }
        .task {
            await viewModel.loadCorrelations()
        }
    }
}

#Preview {
    CorrelationsView()
}
