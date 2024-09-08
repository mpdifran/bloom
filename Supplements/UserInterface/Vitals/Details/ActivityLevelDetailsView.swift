//
//  ActivityLevelDetailsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-09.
//

import SwiftUI
import Charts
import TelemetryDeck

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
                dayOfWeekDistributionView
                workoutSummationViews
            }
            .padding()
            .horizontallyCentered()
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                VitalSummaryDetailTitleView(
                    title: "Activity Level",
                    subtitle: "Last 30 Days"
                )
            }
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
            if let index = ActivityLevelSummary.ActivityLevel.allCases.firstIndex(where: { $0 == viewModel.activityLevelSummary?.details.activityLevel }) {
                selectedActivityLevelIndex = index
            }
            TelemetryDeck.viewScreen("Activity Level Vital Details")
        }
    }
}

private extension ActivityLevelDetailsView {

    @ViewBuilder
    var activityLevelRatioChart: some View {
        if let activityLevelSummary = viewModel.activityLevelSummary {
            VStack(alignment: .leading) {
                VitalDetailChartTitleView(
                    title: "Energy Ratio",
                    value: activityLevelSummary.details.activityLevel?.name ?? "Unknown"
                )

                Chart {
                    ForEach(activityLevelSummary.details.energyRatioSamples) { ratio in
                        BarMark(
                            x: .value("Date", ratio.date),
                            yStart: .value("", 1),
                            yEnd: .value("Ratio", ratio.value)
                        )
                        .foregroundStyle(color(for: ratio.value))
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

                DetailInfoCardView {
                    Text("Energy Ratio is the ratio between your Basal Energy and TDEE (Total Daily Energy Exertion) for a given day. The higher the ratio, the more active you were.")
                }
            }
        }
    }

    var chartMax: Double {
        guard let maxValue = viewModel.activityLevelSummary?.details.energyRatioSamples.max(keyPath: \.value) else { return 2 }

        return max(maxValue * 1.1, 2)
    }

    func color(for ratio: Double) -> Color {
        let activityLevel = ActivityLevelSummary.ActivityLevel(ratio)

        if activityLevel == selectedLevel {
            return selectedLevel.color
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
            VitalDetailChartTitleView(title: "By Level", value: "")
            ActivityLevelDistributionView(ratioDistribution: viewModel.activityLevelSummary?.details.activityLevelRatioDistribution ?? [:])
        }
        .cardContainer(fill: .background.secondary)
    }

    @ViewBuilder
    var dayOfWeekDistributionView: some View {
        if let distribution = viewModel.activityLevelSummary?.details.dayOfWeekActivityLevelRatioDistribution() {
            VStack {
                VitalDetailChartTitleView(title: "By Day of Week", value: "")

                Chart {
                    ForEach(distribution.keys.sorted(keyPath: \.self), id: \.self) { dayOfWeek in
                        BarMark(
                            x: .value("Day", dayOfWeek.dayOfWeekLabel),
                            yStart: .value("", 1),
                            yEnd: .value("Average Activity Level", distribution[dayOfWeek, default: 1])
                        )
                        .cornerRadius(5)
                        .foregroundStyle(ActivityLevelSummary.ActivityLevel(distribution[dayOfWeek, default: 1]).color)
                    }
                }
                .chartYScale(domain: 1...((distribution.max(keyPath: \.value) ?? 1.8) * 1.1), range: .plotDimension)
                .chartXScale(domain: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], range: .plotDimension)
                .chartXAxis {
                    AxisMarks(values: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]) { value in
                        AxisGridLine()
                        AxisTick()

                        if let intValue = value.as(Int.self) {
                            AxisValueLabel {
                                Text(intValue.dayOfWeekLabel)
                            }
                        } else {
                            AxisValueLabel()
                        }
                    }
                }
                .frame(height: 200)
            }
            .cardContainer(fill: .background.secondary)
        }
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

private extension Int {

    var dayOfWeekLabel: String {
        switch self {
        case 1: "Sun"
        case 2: "Mon"
        case 3: "Tue"
        case 4: "Wed"
        case 5: "Thu"
        case 6: "Fri"
        case 7: "Sat"
        default: ""
        }
    }
}

#Preview {
    NavigationStack {
        ActivityLevelDetailsView()
    }
}
