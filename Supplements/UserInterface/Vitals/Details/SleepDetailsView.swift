//
//  SleepDetailsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-11.
//

import SwiftUI
import Charts

struct SleepDetailsView: View {

    @ObservedObject private var healthManager = HealthManager.shared
    @ObservedObject private var viewModel = VitalsViewModel.shared

    @State private var showTodayView = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                sleepQualityChart

                viewDailySleepDataButton

                sleepDistributionChart
                    .cardContainer(
                        fill: .background.secondary,
                        includePadding: false
                    )
            }
            .padding()
        }
        .navigationTitle("Sleep Quality")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showTodayView) {
            TodayView()
        }
    }
}

private extension SleepDetailsView {

    var sleepQualityChart: some View {
        VStack(alignment: .leading) {
            VitalDetailChartTitleView(
                title: "Sleep Quality",
                value: viewModel.sleepVitalsSummary?.averageSleepScore.format() ?? ""
            )

            Chart {
                ForEach(healthManager.sleepAnalysis30Days ?? []) { sleepAnalysis in
                    BarMark(
                        x: .value("Date", sleepAnalysis.normalizedDate),
                        y: .value("Sleep Quality", sleepAnalysis.overallScoreDouble)
                    )
                    .foregroundStyle(color(for: sleepAnalysis.overallScoreDouble))
                    .cornerRadius(5)
                }
            }
            .frame(height: 200)
        }
    }

    func color(for sleepScore: Double) -> Color {
        if sleepScore < 4 {
            .pink
        } else if sleepScore < 7 {
            .yellow
        } else if sleepScore < 9 {
            .green
        } else {
            .blue
        }
    }

    @ViewBuilder
    var sleepDistributionChart: some View {
        if let summary = viewModel.sleepVitalsSummary {
            VStack(alignment: .leading) {
                VitalDetailChartTitleView(
                    title: "Sleep Stages",
                    value: ""
                )
                .padding(.horizontal)

                Divider()

                PillRangeChart(
                    title: "REM Sleep",
                    unitString: "%",
                    value: (summary.averageREMSleepPercent * 100),
                    minValue: 20,
                    maxValue: 25
                )
                .tint(.remSleep)

                Divider()

                PillRangeChart(
                    title: "Core Sleep",
                    unitString: "%",
                    value: (summary.averageCoreSleepPercent * 100),
                    minValue: 45,
                    maxValue: 50
                )
                .tint(.coreSleep)

                Divider()

                PillRangeChart(
                    title: "Deep Sleep",
                    unitString: "%",
                    value: (summary.averageDeepSleepPercent * 100),
                    minValue: 15,
                    maxValue: 25
                )
                .tint(.deepSleep.lighter())

                PillRangeChart(
                    title: "Awake",
                    unitString: "%",
                    value: (summary.averageAwakeSleepPercent * 100),
                    minValue: 0,
                    maxValue: 5
                )
                .tint(.awakeSleep)
            }
            .padding(.vertical)
        }
    }

    var viewDailySleepDataButton: some View {
        Button {
            showTodayView = true
        } label: {
            HStack {
                Label("View All Data", systemImage: "bed.double.fill")
                Spacer()
                Image(systemName: "chevron.forward")
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.zone)
        .tint(.coreSleep)
    }
}

#Preview {
    NavigationView {
        SleepDetailsView()
    }
}
