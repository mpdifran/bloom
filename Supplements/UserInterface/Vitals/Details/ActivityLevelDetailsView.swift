//
//  ActivityLevelDetailsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-09.
//

import SwiftUI
import Charts

struct ActivityLevelDetailsView: View {

    @State private var selectedActivityLevelIndex = 0
    @State private var workoutSummations = [WorkoutSummation]()

    @ObservedObject private var viewModel = VitalsViewModel.shared

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                activityLevelRatioChart
                ratioDistributionView
                workoutSummationViews
            }
            .padding()
            .horizontallyCentered()
        }
        .navigationTitle("Activity Level")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            let samples = await HealthManager.shared.fetchWorkoutSummation(pastDays: 30)
            await MainActor.run {
                self.workoutSummations = samples
            }
        }
        .onAppear {
            feedbackGenerator.prepare()
            if let index = ActivityLevelSummary.ActivityLevel.allCases.firstIndex(where: { $0 == viewModel.activityLevelSummary?.activityLevel }) {
                selectedActivityLevelIndex = index
            }
        }
    }
}

private extension ActivityLevelDetailsView {

    @ViewBuilder
    var activityLevelRatioChart: some View {
        if let activityLevelSummary = viewModel.activityLevelSummary {
            VStack(alignment: .leading) {
                VitalDetailChartTitleView(
                    title: "Activity Ratio",
                    value: activityLevelSummary.activityLevel.name
                )

                Chart {
                    ForEach(activityLevelSummary.energyRatioSamples) { ratio in
                        BarMark(
                            x: .value("Date", ratio.date),
                            yStart: .value("", 1),
                            yEnd: .value("Ratio", ratio.quantity)
                        )
                        .foregroundStyle(color(for: ratio.quantity))
                    }

                    RectangleMark(
                        yStart: .value("Min", selectedLevel.range.lowerBound),
                        yEnd: .value("Max", min(selectedLevel.range.upperBound, chartMax))
                    )
                    .foregroundStyle(selectedLevel.color.opacity(0.3))

                    RuleMark(y: .value("Min", selectedLevel.range.lowerBound))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundStyle(selectedLevel.color)

                    if selectedLevel.range.upperBound < chartMax {
                        RuleMark(y: .value("Max", min(selectedLevel.range.upperBound, chartMax)))
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                            .foregroundStyle(selectedLevel.color)
                    }
                }
                .chartYScale(domain: 1...chartMax, range: .plotDimension(startPadding: 10, endPadding: 0))
                .frame(height: 300)
                .clipped()

                levelPicker
            }
        }
    }

    var chartMax: Double {
        guard let max = viewModel.activityLevelSummary?.energyRatioSamples.max(keyPath: \.quantity) else { return 2 }

        return max * 1.1
    }

    func color(for ratio: Double) -> Color {
        let activityLevel = ActivityLevelSummary.ActivityLevel(ratio)

        if activityLevel == selectedLevel {
            return .green
        }
        return .green.opacity(0.3)
    }

    var selectedLevel: ActivityLevelSummary.ActivityLevel {
        ActivityLevelSummary.ActivityLevel.allCases[selectedActivityLevelIndex]
    }

    var levelPicker: some View {
        Button {
            selectedActivityLevelIndex = (selectedActivityLevelIndex + 1) % ActivityLevelSummary.ActivityLevel.allCases.count
            feedbackGenerator.impactOccurred()
        } label: {
            HStack {
                Text("Level")

                Spacer()

                Text(selectedLevel.name)
            }
        }
        .buttonStyle(.zone)
        .tint(selectedLevel.color)
    }

    var ratioDistributionView: some View {
        VStack {
            VitalDetailChartTitleView(title: "Daily Activity Level Distribution", value: "")
            ActivityLevelDistributionView(ratioDistribution: viewModel.activityLevelSummary?.activityLevelRatioDistribution ?? [:])
        }
        .cardContainer(fill: .background.secondary)
    }

    @ViewBuilder
    var workoutSummationViews: some View {
        if workoutSummations.isNotEmpty {
            VStack {
                VitalDetailChartTitleView(title: "Workouts", value: "")
                    .padding(.horizontal)

                ForEach(workoutSummations) { workoutSummation in
                    WorkoutSummationCell(workoutSummation: workoutSummation)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ActivityLevelDetailsView()
    }
}
