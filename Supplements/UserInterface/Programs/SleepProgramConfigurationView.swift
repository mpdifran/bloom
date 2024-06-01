//
//  SleepProgramConfigurationView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-31.
//

import SwiftUI
import AppUI

struct SleepProgramConfigurationView: View {

    @ObservedObject private var viewModel = SleepProgramConfigurationViewModel()

    @State private var temperature: String = "Cold"
    @State private var sound: String = "Quiet"
    @State private var light: String = "Dark"

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                environmentSection
                sleepSection
                physicalActivitySection
            }
            .navigationTitle("Sleep Program")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .shelf {
                Button(action: {
                    
                }, label: {
                    HStack {
                        Spacer()
                        Text("Start Program")
                        Spacer()
                    }
                })
                .buttonStyle(.tertiary)
            }
            .task {
                await viewModel.loadData()
            }
        }
        .tint(.coreSleep)
    }
}

private extension SleepProgramConfigurationView {

    var environmentSection: some View {
        Section {
            SleepProgramSectionHeader(
                title: "Environment",
                subtitle: "",
                systemImage: "thermometer.snowflake"
            )
            .tint(.remSleep)

            Picker(selection: $temperature) {
                Text("Cold")
                    .tag("Cold")
                Text("Warm")
                    .tag("Warm")
                Text("Hot")
                    .tag("Hot")
            } label: {
                Text("Temperature")
            }

            Picker(selection: $sound) {
                Text("Quiet")
                    .tag("Quiet")
                Text("Intermittent Sounds")
                    .tag("Intermittent Sounds")
                Text("Loud")
                    .tag("Loud")
            } label: {
                Text("Sound")
            }

            Picker(selection: $light) {
                Text("Dark")
                    .tag("Dark")
                Text("Some Light")
                    .tag("Some Light")
                Text("Bright")
                    .tag("Bright")
            } label: {
                Text("Darkness")
            }

            Text(sleepEnvironmentSummary)
                .foregroundStyle(.secondary)
        }
    }

    var physicalActivitySection: some View {
        Section {
            SleepProgramSectionHeader(
                title: "Workouts",
                subtitle: "Last Two Weeks",
                systemImage: "figure.run"
            )
            .tint(.green)

            HStack {
                VStack(alignment: .leading) {
                    LabelledMetricView(
                        label: "Amount",
                        value: "\(viewModel.workoutSummary.count) Workouts"
                    )
                    .tint(.yellow)

                    LabelledMetricView(
                        label: "Duration",
                        value: "\(String(format: "%.0f", workoutDurationSumMinutes)) Minutes"
                    )
                    .tint(.green)

                    LabelledMetricView(
                        label: "Energy Burned",
                        value: "\(String(format: "%.0f", energyBurned)) CAL"
                    )
                    .tint(.pink)
                }

                Spacer()

                ProgressRingView(
                    progress: .constant(workoutDurationScore),
                    dimension: 80,
                    color: .green
                )
            }

            Text(workoutSummary)
                .foregroundStyle(.secondary)
        }
    }

    var sleepSection: some View {
        Section {
            SleepProgramSectionHeader(
                title: "Sleep",
                subtitle: "Last Two Weeks",
                systemImage: "bed.double.fill"
            )
            .tint(.coreSleep)

            SleepCategoryCell(
                title: "Avg REM Sleep",
                color: .remSleep,
                percent: viewModel.sleepAnalyses.average(keyPath: \.remSleepPercent) * 100,
                unit: "%"
            )

            SleepCategoryCell(
                title: "Avg Core Sleep",
                color: .coreSleep,
                percent: viewModel.sleepAnalyses.average(keyPath: \.coreSleepPercent) * 100,
                unit: "%"
            )

            SleepCategoryCell(
                title: "Avg Deep Sleep",
                color: .deepSleep,
                percent: viewModel.sleepAnalyses.average(keyPath: \.deepSleepPercent) * 100,
                unit: "%"
            )

            SleepCategoryCell(
                title: "Sleep Duration",
                color: .green,
                percent: viewModel.sleepAnalyses.average(keyPath: \.overallHours),
                unit: "hours"
            )
        }
    }
}

private extension SleepProgramConfigurationView {

    var sleepEnvironmentSummary: String {
        switch (temperature, sound, light) {
        case ("Cold", "Quiet", "Dark"):
            "These are ideal conditions for a good night sleep."
        case ("Hot", "Loud", _),
            ("Hot", _, "Bright"),
            (_, "Loud", "Bright"):
            "These are not very good conditions for sleep."
        default:
            "There's some room for improvement on your sleep environment."
        }
    }

    var workoutSummary: String {
        if workoutDurationScore < 0.5 {
            "More daily exercise can help with a good night sleep."
        } else if workoutDurationScore < 1 {
            "Aiming for a bit more exercise each day will help with your sleep."
        } else {
            "You're getting at least 30 minutes of exercise, great job!"
        }
    }

    var workoutDurationScore: CGFloat {
        workoutDurationSumMinutes / 14 / 30
    }

    var workoutDurationSumMinutes: TimeInterval {
        viewModel.workoutSummary.reduce(0) { partialResult, workoutSummary in
            partialResult + workoutSummary.duration
        } / 60
    }

    var energyBurned: Double {
        viewModel.workoutSummary.reduce(0) { partialResult, workoutSummary in
            partialResult + workoutSummary.energyBurned.value
        } / 1000
    }

    func sleepAverage(keyPath: KeyPath<SleepAnalysis, Double>) -> Double {
        viewModel.sleepAnalyses.average(keyPath: keyPath)
    }
}

struct SleepCategoryCell: View {
    let title: String
    let color: Color
    let percent: Double
    let unit: String

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(title)

            Spacer()

            Text("\(percent, specifier: "%.1f") \(unit)")
        }
    }
}

#Preview {
    SleepProgramConfigurationView()
}
