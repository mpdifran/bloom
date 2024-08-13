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

    @State private var selectedSleepQualityIndex = 0
    @State private var showTodayView = false

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                sleepQualityChart

                sleepDistributionChart
                    .cardContainer(
                        fill: .background.secondary,
                        includePadding: false
                    )

                viewDailySleepDataButton
            }
            .padding()
        }
        .navigationTitle("Sleep Quality")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showTodayView) {
            TodayView()
        }
        .onAppear {
            feedbackGenerator.prepare()
        }
    }
}

private extension SleepDetailsView {

    var selectedSleepQuality: SleepVitalsMonthlySummary.SleepQuality? {
        guard selectedSleepQualityIndex > 0 else { return nil }

        return SleepVitalsMonthlySummary.SleepQuality.allCases[selectedSleepQualityIndex - 1]
    }

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

            Button  {
                selectedSleepQualityIndex = (selectedSleepQualityIndex + 1) % (SleepVitalsMonthlySummary.SleepQuality.allCases.count + 1)
                feedbackGenerator.impactOccurred()
            } label: {
                HStack {
                    Text("Sleep Quality")

                    Spacer()

                    Text(selectedSleepQuality?.name ?? "All")
                }
            }
            .buttonStyle(.zone)
            .tint(selectedSleepQuality?.color ?? .coreSleep)
        }
    }

    func color(for sleepScore: Double) -> Color {
        guard let quality = selectedSleepQuality else { return .coreSleep }

        if 
            sleepScore < 4 && quality == .poor ||
            sleepScore >= 4 && sleepScore < 7 && quality == .low ||
            sleepScore >= 7 && sleepScore < 9 && quality == .good ||
            sleepScore >= 9 && quality == .great
        {
            return quality.color
        }

        return .coreSleep.opacity(0.3)
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
            .containerShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.coreSleep)
        .cardContainer(fill: .background.secondary)
    }
}

#Preview {
    NavigationView {
        SleepDetailsView()
    }
}
