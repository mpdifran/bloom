//
//  CardioFitnessDetailsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-11.
//

import SwiftUI
import Charts

struct CardioFitnessDetailsView: View {
    
    @State private var selectedFitnessLevelIndex: Int = 0
    @State private var vo2MaxSamples = [DateAverageQuantitySample]()

    @ObservedObject private var viewModel = VitalsViewModel.shared

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    private let fitnessLevels: [CardioFitnessMonthlySummary.FitnessLevel] = [
        .low,
        .belowAverage,
        .aboveAverage,
        .high
    ]

    var body: some View {
        ScrollView {
            vo2MaxChart
                .padding()
            heartRateRecoveryChart
                .padding()
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                VitalSummaryDetailTitleView(
                    title: "Cardio Fitness",
                    subtitle: "Last 30 Days"
                )
            }
        }
        .navigationTitle("Cardio Fitness")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.default, value: selectedFitnessLevelIndex)
        .task {
            let samples = await HealthManager.shared.fetchVO2Max(numPastDays: 30)
            await MainActor.run {
                self.vo2MaxSamples = samples
            }
        }
        .onAppear {
            feedbackGenerator.prepare()
            if let level = viewModel.cardioFitnessSummary?.vo2MaxFitnessLevel, let index = fitnessLevels.firstIndex(of: level) {
                self.selectedFitnessLevelIndex = index
            }
        }
    }
}

private extension CardioFitnessDetailsView {

    var fitnessLevel: CardioFitnessMonthlySummary.FitnessLevel {
        fitnessLevels[selectedFitnessLevelIndex]
    }

    var selectedFitnessLevelRanges: (Double, Double)? {
        guard let goal = HealthManager.shared.goalVO2MaxForUser() else { return nil }

        switch selectedFitnessLevelIndex {
        case 0:
            return (0, goal.2)
        case 1:
            return (goal.2, goal.1)
        case 2:
            return (goal.1, goal.0)
        case 3:
            return (goal.0, max((maxVO2Max ?? 0) * 1.1, 60))
        default:
            return nil
        }
    }

    var maxVO2Max: Double? {
        vo2MaxSamples.max(keyPath: \.averageQuantity)
    }

    var minVO2Max: Double? {
        vo2MaxSamples.min(keyPath: \.averageQuantity)
    }

    var chartMin: Double {
        let rangeMin = selectedFitnessLevelRanges?.0

        if let min = [rangeMin, minVO2Max].unwrap().min() {
            return min * 0.9
        }
        return 20
    }

    var chartMax: Double {
        let rangeMax = selectedFitnessLevelRanges?.1

        if let max = [rangeMax, maxVO2Max].unwrap().max() {
            return max * 1.1
        }
        return 50
    }

    var vo2MaxChart: some View {
        VStack(alignment: .leading) {
            VitalDetailChartTitleView(title: "VO₂ Max", value: viewModel.cardioFitnessSummary?.averageVO2Max?.format() ?? "")

            Group {
                if vo2MaxSamples.isEmpty {
                    ContentUnavailableView(
                        "No Data Available",
                        systemImage: "heart.fill",
                        description: Text("There are no VO₂ Max samples in the past month.")
                    )
                } else {
                    Chart {
                        if let selectedFitnessLevelRanges {
                            RectangleMark(
                                yStart: .value("Min", selectedFitnessLevelRanges.0),
                                yEnd: .value("Max", selectedFitnessLevelRanges.1)
                            )
                            .foregroundStyle(fitnessLevel.color.opacity(0.3))

                            RuleMark(y: .value("Min", selectedFitnessLevelRanges.0))
                                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                                .foregroundStyle(fitnessLevel.color)
                            RuleMark(y: .value("Max", selectedFitnessLevelRanges.1))
                                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                                .foregroundStyle(fitnessLevel.color)
                        }

                        ForEach(vo2MaxSamples) { sample in
                            LineMark(
                                x: .value("Date", sample.date),
                                y: .value("VO₂ Max", sample.averageQuantity)
                            )
                            .foregroundStyle(viewModel.cardioFitnessSummary?.vo2MaxFitnessLevel.color ?? .pink)
                            PointMark(
                                x: .value("Date", sample.date),
                                y: .value("VO₂ Max", sample.averageQuantity)
                            )
                            .foregroundStyle(viewModel.cardioFitnessSummary?.vo2MaxFitnessLevel.color ?? .pink)
                        }
                    }
                    .chartYScale(domain: chartMin...chartMax, range: .plotDimension)
                }
            }
            .frame(height: 250)

            if vo2MaxSamples.isNotEmpty {
                Button {
                    selectedFitnessLevelIndex = (selectedFitnessLevelIndex + 1) % fitnessLevels.count
                    feedbackGenerator.impactOccurred()
                } label: {
                    HStack {
                        Text("Fitness Level")

                        Spacer()

                        Text(fitnessLevel.name)
                    }
                }
                .buttonStyle(.zone)
                .tint(fitnessLevel.color)

                DetailInfoCardView {
                    Text(fitnessLevel.summary)
                    Text("Fitness levels derived from the Fitness Registry and Importance of Exercise National Database (FRIEND).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    var heartRateRecoveryChart: some View {
        VStack(alignment: .leading) {
            VitalDetailChartTitleView(
                title: "Heart Rate Recovery",
                value: (viewModel.cardioFitnessSummary?.averageHeartRateRecovery?.format() ?? "unknown") + " bpm"
            )

            Chart {
                RuleMark(x: .value("Min", Double.minHeartRateRecovery))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                    .foregroundStyle(.pink)

                RectangleMark(
                    xStart: .value("Min", Double.minHeartRateRecovery),
                    xEnd: .value("", maxValue)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.pink.opacity(0.3), .pink.opacity(0.05)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

                if let lastMonthHeartRateRecovery = viewModel.cardioFitnessSummary?.lastMonthAverageHeartRateRecovery {
                    BarMark(
                        x: .value("Heart Rate Recovery", lastMonthHeartRateRecovery),
                        y: .value("Time Peroid", "Last Month")
                    )
                    .foregroundStyle(.gray)
                    .cornerRadius(10)
                }
                if let heartRateRecovery = viewModel.cardioFitnessSummary?.averageHeartRateRecovery {
                    BarMark(
                        x: .value("Heart Rate Recovery", heartRateRecovery),
                        y: .value("Time Peroid", "This Month")
                    )
                    .foregroundStyle(.pink)
                    .cornerRadius(10)
                }
            }
            .chartYAxis {
                AxisMarks(values: ["Last Month", "This Month"]) {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
            .chartYScale(domain: ["Last Month", "This Month"])
            .chartXScale(domain: 0...maxValue, range: .plotDimension)
            .frame(height: 150)
        }
    }

    var maxValue: Double {
        let maxDataPoint = max(
            viewModel.cardioFitnessSummary?.lastMonthAverageHeartRateRecovery ?? 0,
            viewModel.cardioFitnessSummary?.averageHeartRateRecovery ?? 0
        )

        return max(maxDataPoint * 1.1, 40)
    }
}

#Preview {
    NavigationView {
        CardioFitnessDetailsView()
    }
}
