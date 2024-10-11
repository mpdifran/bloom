//
//  SleepDetailsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-11.
//

import SwiftUI
import Charts
import TelemetryDeck

struct SleepDetailsView: View {

    @ObservedObject private var healthManager = HealthManager.shared
    private let viewModel = VitalsViewModel.shared

    @State private var selectedSleepQualityIndex = 0
    @State private var showTodayView = false
    @State private var sleepAnalyses = [SleepAnalysis]()

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
        .toolbar {
            ToolbarItem(placement: .principal) {
                VitalSummaryDetailTitleView(
                    title: "Sleep Quality",
                    subtitle: "Last 30 Days"
                )
            }
        }
        .navigationTitle("Sleep Quality")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showTodayView) {
            SleepDayView()
        }
        .onAppear {
            feedbackGenerator.prepare()
            TelemetryDeck.viewScreen("Sleep Vital Details")
        }
        .task {
            let analyses = await HealthStoreFetcher.shared.fetchSleepAnalysis(dateRange: .trailingMonthsFromNow(1))

            await MainActor.run {
                self.sleepAnalyses = analyses
            }
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
                value: viewModel.sleepVitalsSummary?.details.averageSleepScore?.format(using: .oneDecimalPlace) ?? ""
            )

            Chart {
                ForEach(sleepAnalyses) { sleepAnalysis in
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
        let sleepQuality = SleepVitalsMonthlySummary.SleepQuality(sleepScore: sleepScore)

        if selectedSleepQuality == nil {
            return sleepQuality.color
        } else {
            return sleepQuality.color.opacity(selectedSleepQuality == sleepQuality ? 1 : 0.3)
        }
    }

    @ViewBuilder
    var sleepDistributionChart: some View {
        if 
            let summary = viewModel.sleepVitalsSummary,
            let averageREMSleepPercent = summary.details.averageREMSleepPercent,
            let averageCoreSleepPercent = summary.details.averageCoreSleepPercent,
            let averageDeepSleepPercent = summary.details.averageDeepSleepPercent,
            let averageAwakeSleepPercent = summary.details.averageAwakeSleepPercent
        {
            VStack(alignment: .leading) {
                VitalDetailChartTitleView(
                    title: "Sleep Stages",
                    value: ""
                )
                .padding(.horizontal)

                Divider()

                PillRangeChart(
                    title: "REM Sleep",
                    quantityString: "",
                    unitString: "%",
                    value: (averageREMSleepPercent * 100),
                    minValue: 20,
                    maxValue: 25
                )
                .tint(.remSleep)

                Divider()

                PillRangeChart(
                    title: "Core Sleep",
                    quantityString: "",
                    unitString: "%",
                    value: (averageCoreSleepPercent * 100),
                    minValue: 45,
                    maxValue: 50
                )
                .tint(.coreSleep)

                Divider()

                PillRangeChart(
                    title: "Deep Sleep",
                    quantityString: "",
                    unitString: "%",
                    value: (averageDeepSleepPercent * 100),
                    minValue: 15,
                    maxValue: 25
                )
                .tint(.deepSleep.lighter())

                PillRangeChart(
                    title: "Awake",
                    quantityString: "",
                    unitString: "%",
                    value: (averageAwakeSleepPercent * 100),
                    minValue: 0,
                    maxValue: 5
                )
                .tint(.awakeSleep)
            }
            .padding(.vertical)
        }
    }

    var viewDailySleepDataButton: some View {
        HStack {
            Label("View All Data", systemImage: "bed.double.fill")
            Spacer()
            Image(systemName: "chevron.forward")
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(.coreSleep)
        .cardContainer(fill: .background.secondary)
        .onTapGesture {
            showTodayView = true
        }
    }
}

#Preview {
    NavigationView {
        SleepDetailsView()
    }
}
