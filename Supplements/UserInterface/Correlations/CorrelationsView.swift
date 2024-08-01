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
            ScrollView {
                VStack {
                    if let data = viewModel.timeInDaylightSleepLengthCorrelationData {
                        CorrelationChartCell(
                            title: "Time in Daylight vs Sleep Length",
                            dataSet: data.0.suffix(30),
                            correlationCoefficient: data.1,
                            aConfig: .init(title: "Time in Daylight", color: .orange, unit: "h"),
                            bConfig: .init(title: "Sleep Length", color: .coreSleep, unit: "h")
                        )
                        .cardContainer()
                        .transition(.blurReplace)
                    }
                    if let data = viewModel.activeEnergySleepLengthCorrelationData {
                        CorrelationChartCell(
                            title: "Active Energy vs Sleep Length",
                            dataSet: data.0.suffix(30),
                            correlationCoefficient: data.1,
                            aConfig: .init(title: "Active Energy", color: .green, unit: "Cal"),
                            bConfig: .init(title: "Sleep Length", color: .coreSleep, unit: "h")
                        )
                        .cardContainer()
                        .transition(.blurReplace)
                    }
                    if let data = viewModel.exerciseMinutesSleepScoreCorrelationData {
                        CorrelationChartCell(
                            title: "Exercise Minutes vs Sleep Quality",
                            dataSet: data.0.suffix(30),
                            correlationCoefficient: data.1,
                            aConfig: .init(title: "Exercise Minutes", color: .yellow, unit: "min"),
                            bConfig: .init(title: "Sleep Quality", color: .remSleep, unit: "")
                        )
                        .cardContainer()
                        .transition(.blurReplace)
                    }
                }
                .horizontallyCentered()
                .padding()
            }
            .background(
                Rectangle()
                    .fill(.background.secondary)
                    .ignoresSafeArea()
            )
            .navigationTitle("Insights")
            .animation(.default, value: viewModel.timeInDaylightSleepLengthCorrelationData == nil)
            .animation(.default, value: viewModel.activeEnergySleepLengthCorrelationData == nil)
            .animation(.default, value: viewModel.exerciseMinutesSleepScoreCorrelationData == nil)
        }
        .tabItem {
            Label("Insights", systemImage: "chart.xyaxis.line")
        }
    }
}

#Preview {
    CorrelationsView()
}
