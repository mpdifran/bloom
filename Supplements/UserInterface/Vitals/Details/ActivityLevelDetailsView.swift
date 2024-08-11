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
                        LineMark(
                            x: .value("Date", ratio.date),
                            y: .value("Ratio", ratio.quantity)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(activityLevelSummary.activityLevel.color)
                    }

                    RectangleMark(
                        yStart: .value("Min", selectedLevel.range.lowerBound),
                        yEnd: .value("Max", selectedLevel.range.upperBound)
                    )
                    .foregroundStyle(selectedLevel.color.opacity(0.3))

                    RuleMark(y: .value("Min", selectedLevel.range.lowerBound))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundStyle(selectedLevel.color)

                    RuleMark(y: .value("Max", selectedLevel.range.upperBound))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundStyle(selectedLevel.color)
                }
                .chartYScale(domain: 1...2.5, range: .plotDimension(startPadding: 10, endPadding: 10))
                .frame(height: 300)
                .clipped()

                levelPicker
            }
        }
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
            .bold()
            .foregroundStyle(.invertedText)
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(selectedLevel.color)
            }
        }
        .buttonStyle(.plain)
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
