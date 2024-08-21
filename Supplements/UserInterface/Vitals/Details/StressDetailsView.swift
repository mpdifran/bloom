//
//  StressDetailsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-08.
//

import SwiftUI
import Charts

struct StressDetailsView: View {
    
    @State private var heartRateVariabilitySamples = [DateAverageQuantitySample]()
    @State private var restingHeartRateSamples = [DateQuantitySampleLegacy]()

    @ObservedObject private var viewModel = VitalsViewModel.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if
                    let systolic = viewModel.stressSummary?.bloodPressureSystolic,
                    let diastloic = viewModel.stressSummary?.bloodPressureDiastolic 
                {
                    BloodPressureStatusView(
                        systolic: systolic,
                        diastolic: diastloic,
                        lastMonthSystolic: viewModel.stressSummary?.lastMonthBloodPressureSystolic,
                        lastMonthDiastolic: viewModel.stressSummary?.lastMonthBloodPressureDiastolic
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
    }
}

private extension StressDetailsView {

    var restingHeartRateChart: some View {
        VStack(alignment: .leading) {
            if let restingHeartRate = viewModel.stressSummary?.restingHeartRate?.format() {
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
                    .foregroundStyle(.pink)
                    .interpolationMethod(.catmullRom)
                }
                let goal = HealthManager.shared.goalRestingHeartRateForUser()

                RuleMark(y: .value("Min RHR", goal.0))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                    .foregroundStyle(.pink)

                RuleMark(y: .value("Max RHR", goal.1))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                    .foregroundStyle(.pink)

                RectangleMark(
                    yStart: .value("Min RHR", goal.0),
                    yEnd: .value("Max RHR", goal.1)
                )
                .foregroundStyle(.pink.opacity(0.3))
            }
            .chartYScale(
                domain: (minRestingHeartRate ?? 0)...(maxRestingHeartRate ?? 100),
                range: .plotDimension
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

    var minRestingHeartRate: Double? {
        restingHeartRateSamples.min(keyPath: \.quantity)
    }

    var maxRestingHeartRate: Double? {
        restingHeartRateSamples.max(keyPath: \.quantity)
    }

    var restingHeartRateDescription: String? {
        guard let restingHeartRate = viewModel.stressSummary?.restingHeartRate else {
            return nil
        }

        let goal = HealthManager.shared.goalRestingHeartRateForUser()

        if restingHeartRate < goal.1 {
            return "A low resting heart rate can be a good indicator of an efficient metabolism, can reduce your risk of heart disease, and help you live longer."
        } else {
            return "A high resting heart rate can increase your risk of diabetes, stroke, and heart disease."
        }
    }

    var heartRateVariabilityChart: some View {
        VStack(alignment: .leading) {
            if let hrv = viewModel.stressSummary?.avgHeartRateVariability?.format() {
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
                    .foregroundStyle(.pink)
                }

                if let hrv = viewModel.stressSummary?.avgHeartRateVariability {
                    RuleMark(y: .value("Average HRV", hrv))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundStyle(.pink)
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
