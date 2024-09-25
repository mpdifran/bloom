//
//  StressDetailsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-08.
//

import SwiftUI
import Charts
import TelemetryDeck

struct StressDetailsView: View {

    @ObservedObject private var viewModel = VitalsViewModel.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                stressLevelChart
                    .padding()

                if
                    let systolic = viewModel.stressSummary?.details.bloodPressureSystolic,
                    let diastloic = viewModel.stressSummary?.details.bloodPressureDiastolic
                {
                    BloodPressureStatusView(
                        systolic: systolic.doubleValue(for: .millimeterOfMercury()),
                        diastolic: diastloic.doubleValue(for: .millimeterOfMercury()),
                        lastMonthSystolic: viewModel.stressSummary?.lastMonthDetails.bloodPressureSystolic?.doubleValue(for: .millimeterOfMercury()),
                        lastMonthDiastolic: viewModel.stressSummary?.lastMonthDetails.bloodPressureDiastolic?.doubleValue(for: .millimeterOfMercury())
                    )
                }

                restingHeartRateChart
                    .padding()

                heartRateVariabilityChart
                    .padding()
            }
            .horizontallyCentered()
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                VitalSummaryDetailTitleView(
                    title: "Stress Levels",
                    subtitle: "Last 30 Days"
                )
            }
        }
        .navigationTitle("Stress Levels")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            TelemetryDeck.viewScreen("Stress Vital Details")
        }
    }
}

private extension StressDetailsView {

    var stressLevelChart: some View {
        VStack(alignment: .leading) {
            if let averageStressLevel = viewModel.stressSummary?.details.averageStressLevel {
                VitalDetailChartTitleView(
                    title: "Daily Stress Levels",
                    value: "\(StressMonthlySummary.Level(score: averageStressLevel).name)"
                )
            } else {
                VitalDetailChartTitleView(
                    title: "Daily Stress Levels",
                    valueLabel: "",
                    value: ""
                )
            }

            Chart {
                ForEach(viewModel.stressSummary?.details.stressLevels ?? []) { stressLevel in
                    BarMark(
                        x: .value("Date", stressLevel.date),
                        y: .value("Stress Level", stressLevel.stressScore)
                    )
                    .foregroundStyle(stressLevel.level.color)
                }
            }
            .chartYScale(
                domain: -1...1,
                range: .plotDimension(padding: 10)
            )
            .chartForegroundStyleScale([
                StressMonthlySummary.Level.relaxed.name: StressMonthlySummary.Level.relaxed.color,
                StressMonthlySummary.Level.mild.name: StressMonthlySummary.Level.mild.color,
                StressMonthlySummary.Level.high.name: StressMonthlySummary.Level.high.color,
                StressMonthlySummary.Level.severe.name: StressMonthlySummary.Level.severe.color
            ])
            .frame(height: 200)

            DetailInfoCardView {
                Text("Your stress level can fluctuate day to day. It's normal to have some days of high stress, but prolonged stress can be harmful to your overall health. Bloom factors in your blood pressure, resting heart rate, and heart rate variability when calculating your stress level.")
            }
            .padding(.top)
        }
    }
}

private extension StressDetailsView {

    var restingHeartRateChart: some View {
        VStack(alignment: .leading) {
            if let restingHeartRate = viewModel.stressSummary?.details.averageRestingHeartRate {
                VitalDetailChartTitleView(
                    title: "Resting Heart Rate",
                    value: "\(restingHeartRate.format()) bpm"
                )
            } else {
                VitalDetailChartTitleView(
                    title: "Resting Heart Rate",
                    valueLabel: "",
                    value: ""
                )
            }

            Chart {
                ForEach(viewModel.stressSummary?.details.restingHeartRate ?? []) { sample in
                    LineMark(
                        x: .value("Date", sample.date),
                        y: .value("Resting Heart Rate", sample.quantity.doubleValue(for: .bpm()))
                    )
                    .foregroundStyle(.mutedRed)
                    .interpolationMethod(.catmullRom)
                }
                let goal = HealthManager.shared.goalRestingHeartRateForUser()

                RuleMark(y: .value("Max RHR", goal.1))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                    .foregroundStyle(.mutedRed)

                RectangleMark(
                    yStart: .value("", goal.1 - 20),
                    yEnd: .value("Max RHR", goal.1)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            .mutedRed.opacity(0.3),
                            .clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .chartYScale(
                domain: chartMin...chartMax,
                range: .plotDimension(padding: 10)
            )
            .frame(height: 160)

            if let restingHeartRateDescription {
                DetailInfoCardView {
                    Text(restingHeartRateDescription)
                }
                .padding(.top)
            }
        }
    }

    var chartMin: Double {
        let goal = HealthManager.shared.goalRestingHeartRateForUser()

        return min(minRestingHeartRate ?? 0, goal.1 - 20)
    }

    var chartMax: Double {
        let goal = HealthManager.shared.goalRestingHeartRateForUser()

        return max(maxRestingHeartRate ?? 100, goal.1)
    }

    var minRestingHeartRate: Double? {
        viewModel.stressSummary?.details.restingHeartRate.map({ $0.quantity.doubleValue(for: .bpm()) }).min()
    }

    var maxRestingHeartRate: Double? {
        viewModel.stressSummary?.details.restingHeartRate.map({ $0.quantity.doubleValue(for: .bpm()) }).max()
    }

    var restingHeartRateDescription: String? {
        guard let restingHeartRate = viewModel.stressSummary?.details.averageRestingHeartRate else {
            return nil
        }

        let goal = HealthManager.shared.goalRestingHeartRateForUser()

        if restingHeartRate < goal.1 {
            return "A low resting heart rate can be a good indicator of an efficient metabolism, can reduce your risk of heart disease, and help you live longer. For your age and sex, it is recommended your resting heart rate is below \(goal.1.format()) bpm."
        } else {
            return "A high resting heart rate can increase your risk of diabetes, stroke, and heart disease. For your age and sex, it is recommended your resting heart rate is below \(goal.1.format()) bpm."
        }
    }

    var heartRateVariabilityChart: some View {
        VStack(alignment: .leading) {
            if let hrv = viewModel.stressSummary?.details.averageHeartRateVariability?.format() {
                VitalDetailChartTitleView(
                    title: "Heart Rate Variability",
                    value: "\(hrv) ms"
                )
            } else {
                VitalDetailChartTitleView(
                    title: "Heart Rate Variability",
                    valueLabel: "",
                    value: ""
                )
            }

            Chart {
                ForEach(viewModel.stressSummary?.details.heartRateVariability ?? []) { sample in
                    LineMark(
                        x: .value("Date", sample.date),
                        y: .value("Heart Rate Variability", sample.quantity.doubleValue(for: .millisecond()))
                    )
                    .foregroundStyle(.mutedRed)
                }

                if let hrv = viewModel.stressSummary?.details.averageHeartRateVariability {
                    RuleMark(y: .value("Average HRV", hrv))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundStyle(.mutedRed)
                }
            }
            .frame(height: 160)

            DetailInfoCardView {
                Text("Heart Rate Variability is a measure of how quickly you can change your heart rate. A higher value indicates lower stress and more relaxation, and a lower value indicates your body is in stress.")
            }
        }
    }
}

#Preview {
    NavigationStack {
        StressDetailsView()
    }
}
