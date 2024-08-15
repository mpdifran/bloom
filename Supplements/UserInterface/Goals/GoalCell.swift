//
//  GoalCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-31.
//

import SwiftUI
import HealthKit
import Charts
import AppUI

struct GoalCell: View {
    @Binding var goals: [GoalModel]
    let index: Int

    @State private var currentGoal: Double = 0

    @ObservedObject private var vitalsViewModel = VitalsViewModel.shared

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                Image(systemName: goal.systemImage)
                    .font(.largeTitle)
                    .foregroundStyle(goal.metric.measurement.color)
                VStack(alignment: .leading) {
                    Text(goal.title)
                        .font(.title3)
                        .bold()
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Due \(DateFormatter.relativeTimeIntervalDaysFullFromNow(goal.dueDate))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()

                if goals.count > 1 {
                    Menu {
                        Menu("Change Goal", systemImage: "medal") {
                            ForEachEnumerated(goals) { (goalIndex, goal) in
                                Button(goal.title) {
                                    goals.move(fromOffsets: [goalIndex], toOffset: 0)
                                    Task {
                                        await loadCurrentGoalValue()
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                    }
                    .font(.title)
                    .foregroundStyle(goal.metric.measurement.color, .fill)
                }
            }

            barChart

            Text(goal.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let targetVitalModel {
                TargetVitalComponentView(vital: targetVitalModel)
            }
        }
        .animation(.bouncy(duration: 1).delay(Double(index) * 0.3), value: currentGoal)
        .onAppear {
            Task {
                await loadCurrentGoalValue()
            }
        }
    }
}

private extension GoalCell {

    var dateRange: DateRange {
        .startOfWeekToNow()
    }

    var goal: GoalModel {
        goals.first!
    }

    var barChart: some View {
        Chart {
            BarMark(
                x: .value("Current Time", currentGoal),
                y: .value("Week", "This Week")
            )
            .foregroundStyle(goal.metric.measurement.color)
            .cornerRadius(10)

            RuleMark(
                x: .value("Goal", goal.metric.value)
            )
            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
            .foregroundStyle(goal.metric.measurement.color.opacity(0.5))
        }
        .chartXAxis {
            AxisMarks {
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartXScale(
            domain: (0...max(goal.metric.value, currentGoal) * 1.3),
            range: .plotDimension
        )
        .frame(height: 100)
    }
}

private extension GoalCell {

    var targetVitalModel: VitalModel? {
        vitalsViewModel.vitals.first(where: { $0.id == goal.vitalKind })
    }

    func loadCurrentGoalValue() async {
        await MainActor.run {
            self.currentGoal = 0
        }

        let quantity = await goal.metric.quantity(for: dateRange)

        await MainActor.run {
            self.currentGoal = quantity.doubleValue(for: goal.metric.unit)
        }
    }
}

#Preview {
    struct PreviewView: View {
        @State private var goals: [GoalModel] = [
            GoalModel(
                title: "Get More Sunlight",
                systemImage: "sun.max.fill",
                summary: "More sun is good for your body. It also gives you Vitamin D! Aim to get 50 minutes of sunlight this week.",
                dueDate: Date().addingTimeInterval(215453),
                metric: .init(
                    value: 300,
                    unitString: "minute",
                    measurement: .timeInDaylight
                ),
                vitalKind: .sleepQuality
            )
        ]

        var body: some View {
            List {
                GoalCell(
                    goals: $goals,
                    index: 0
                )
            }
        }
    }
    return PreviewView()
}
