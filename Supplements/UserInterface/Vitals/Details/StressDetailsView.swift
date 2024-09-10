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
    
    @State private var heartRateVariabilitySamples = [DateAverageQuantitySample]()
    @State private var restingHeartRateSamples = [DateQuantitySampleLegacy]()

    @ObservedObject private var viewModel = VitalsViewModel.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if
                    let systolic = viewModel.stressSummary?.details.bloodPressureSystolic,
                    let diastloic = viewModel.stressSummary?.details.bloodPressureDiastolic
                {
                    BloodPressureStatusView(
                        systolic: systolic,
                        diastolic: diastloic,
                        lastMonthSystolic: viewModel.stressSummary?.lastMonthDetails.bloodPressureSystolic,
                        lastMonthDiastolic: viewModel.stressSummary?.lastMonthDetails.bloodPressureDiastolic
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
        .task {
            let samples = await HealthManager.shared.fetchRestingHeartRate(period: 30)
            await MainActor.run {
                self.restingHeartRateSamples = samples
            }
        }
        .task {
            let samples = await HealthManager.shared.fetchDailyAverageHeartRateVariability(periodDays: 30)
            await MainActor.run {
                self.heartRateVariabilitySamples = samples
            }
        }
        .onAppear {
            TelemetryDeck.viewScreen("Stress Vital Details")
        }
    }
}

private extension StressDetailsView {

    var restingHeartRateChart: some View {
        VStack(alignment: .leading) {
            if let restingHeartRate = viewModel.stressSummary?.details.restingHeartRate?.format() {
                VitalDetailChartTitleView(
                    title: "Resting Heart Rate",
                    value: "\(restingHeartRate) bpm"
                )
            } else {
                VitalDetailChartTitleView(
                    title: "Resting Heart Rate",
                    valueLabel: "",
                    value: ""
                )
            }

            Chart {
                ForEach(restingHeartRateSamples) { sample in
                    LineMark(
                        x: .value("Date", sample.date),
                        y: .value("Resting Heart Rate", sample.quantity)
                    )
                    .foregroundStyle(.mutedPink)
                    .interpolationMethod(.catmullRom)
                }
                let goal = HealthManager.shared.goalRestingHeartRateForUser()

                RuleMark(y: .value("Max RHR", goal.1))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                    .foregroundStyle(.mutedPink)

                RectangleMark(
                    yStart: .value("", goal.1 - 20),
                    yEnd: .value("Max RHR", goal.1)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            .mutedPink.opacity(0.3),
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
        restingHeartRateSamples.min(keyPath: \.quantity)
    }

    var maxRestingHeartRate: Double? {
        restingHeartRateSamples.max(keyPath: \.quantity)
    }

    var restingHeartRateDescription: String? {
        guard let restingHeartRate = viewModel.stressSummary?.details.restingHeartRate else {
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
            if let hrv = viewModel.stressSummary?.details.avgHeartRateVariability?.format() {
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
                ForEach(heartRateVariabilitySamples) { sample in
                    LineMark(
                        x: .value("Date", sample.date),
                        y: .value("Heart Rate Variability", sample.averageQuantity)
                    )
                    .foregroundStyle(.mutedPink)
                }

                if let hrv = viewModel.stressSummary?.details.avgHeartRateVariability {
                    RuleMark(y: .value("Average HRV", hrv))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundStyle(.mutedPink)
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
