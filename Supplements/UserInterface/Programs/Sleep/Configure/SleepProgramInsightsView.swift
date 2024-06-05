//
//  SleepProgramInsightsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-31.
//

import SwiftUI
import AppUI
import FamilyControls
import ScreenControl

struct SleepProgramInsightsView: View {

    @ObservedObject private var viewModel = SleepProgramInsightsViewModel()
    @ObservedObject private var screenUseController = ScreenUseController.shared

    @State private var temperature: String = "Cold"
    @State private var sound: String = "Quiet"
    @State private var light: String = "Dark"
    @State private var error: Error?

    @State private var isShowingFamilyActivityPicker = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                sleepSection
                environmentSection
                screenUseSection
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
        .alert(error: $error)
        .presentationCompactAdaptation(.fullScreenCover)
    }
}

private extension SleepProgramInsightsView {

    var environmentSection: some View {
        Section {
            SleepProgramSectionHeader(
                title: "Environment",
                subtitle: "During Bedtime",
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

    var screenUseSection: some View {
        Section {
            SleepProgramSectionHeader(
                title: "Device Use",
                subtitle: "During Bedtime",
                systemImage: "apps.iphone"
            )

            Text("Screen time before bed can affect your sleep quality. Allow Bloom to remind you to put your phone away near bedtime.")

            DatePicker(
                "Bedtime",
                selection: $screenUseController.startDate,
                displayedComponents: .hourAndMinute
            )

            DatePicker(
                "Wake Up",
                selection: $screenUseController.endDate,
                displayedComponents: .hourAndMinute
            )

            VStack {
                Button(action: {
                    isShowingFamilyActivityPicker = true
                }, label: {
                    Group {
                        if let summary = screenUseController.activitySelection.summaryText {
                            Text(summary)
                        } else {
                            Text("Select Apps")
                        }
                    }
                    .expandHorizontally()
                })
                .buttonStyle(.tertiary)
                .familyActivityPicker(
                    headerText: "Bloom will restrict usage of these apps during bedtime",
                    isPresented: $isShowingFamilyActivityPicker,
                    selection: $screenUseController.activitySelection
                )

                if screenUseController.isMonitoring {
                    Button(action: {
                        screenUseController.stopMonitoring()
                    }, label: {
                        Text("Stop Monitoring")
                            .expandHorizontally()
                    })
                    .tint(.red)
                    .buttonStyle(.tertiary)
                } else {
                    Button(action: {
                        do {
                            try screenUseController.startMonitoring()
                        } catch {
                            self.error = error
                        }
                    }, label: {
                        Text("Start Monitoring")
                            .expandHorizontally()
                    })
                    .tint(.green)
                    .buttonStyle(.tertiary)
                }
            }
        }
        .tint(.indigo)
    }
}

private extension SleepProgramInsightsView {

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
    SleepProgramInsightsView()
}
