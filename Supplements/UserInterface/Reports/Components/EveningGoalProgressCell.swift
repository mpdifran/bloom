//
//  EveningGoalProgressCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-06.
//

import SwiftUI
import HealthKit

struct EveningGoalProgressCell: View {
    let goal: GoalModel

    @StateObject private var viewModel: GoalDailyUpdateCellViewModel

    init(goal: GoalModel) {
        self.goal = goal
        self._viewModel = StateObject(wrappedValue: GoalDailyUpdateCellViewModel(goal: goal))
    }

    var body: some View {
        HStack {
            Image(systemName: goal.systemImage)
                .font(.largeTitle)
                .foregroundStyle(.tint)
                .minimumScaleFactor(0.1)
                .frame(width: 40)

            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: goal.vitalKind.systemImage)
                    Text(goal.vitalKind.name)
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                Text(goal.title)
                    .font(.title3)
                    .bold()

                if goal.metric.measurement.isDecrease {
                    ProgressView(value: min(remainingValue / goalValue, 1))
                        .scaleEffect(x: -1)
                        .foregroundStyle(.tint)
                } else {
                    ProgressView(value: min(viewModel.dailyValue / goalValue, 1))
                        .foregroundStyle(.tint)
                }

                HStack {
                    if goal.metric.measurement.isDecrease {
                        if remainingValue < 0 {
                            Text("\(remainingValue * -1) \(goal.metric.unitString)")
                                .foregroundStyle(.tint)
                                .contentTransition(.numericText(value: remainingValue))

                            Text("over goal")
                                .foregroundStyle(.secondary)
                        } else {
                            HStack {
                                Text("\(remainingValue.format(using: .oneDecimalPlace)) \(goal.metric.unitString)")
                                    .foregroundStyle(.tint)
                                    .contentTransition(.numericText(value: remainingValue))

                                Text("remaining")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        Text("\(viewModel.dailyValue.format(using: .oneDecimalPlace)) \(goal.metric.unit.unitString)")
                            .foregroundStyle(.tint)
                            .contentTransition(.numericText(value: viewModel.dailyValue))

                        Text("/ \(goalValue.format()) \(goal.metric.unit.unitString)")
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.subheadline)
                .bold()

                Text(dailyComparisonDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            CompletionCheckmarkView(hasCompleted: viewModel.hasCompletedTodayGoal)
        }
        .tint(goal.metric.measurement.color)
        .animation(.easeOut, value: viewModel.dailyValue)
    }
}

private extension EveningGoalProgressCell {

    var remainingValue: Double {
        goalValue - viewModel.dailyValue
    }

    var goalValue: Double {
        (goal.metric.value / 7)
    }

    var dailyComparisonDescription: String {
        let absDifference = abs(viewModel.dailyValue - viewModel.yesterdayValue)
        if absDifference < 0.1 {
            return "This is the same as yesterday."
        }

        if viewModel.dailyValue > viewModel.yesterdayValue {
            let difference = (viewModel.dailyValue - viewModel.yesterdayValue).format(using: .oneDecimalPlace)
            return "This is \(difference) \(goal.metric.unitString) more than yesterday."
        } else {
            let difference = (viewModel.yesterdayValue - viewModel.dailyValue).format(using: .oneDecimalPlace)
            return "This is \(difference) \(goal.metric.unitString) less than yesterday."
        }
    }
}

#Preview {
    List {
        Section("Goals") {
            EveningGoalProgressCell(
                goal: .init(
                    title: "Walking + Running Distance",
                    systemImage: "figure.walk",
                    summary: "Walking and running are good for you.",
                    dueDate: .now.addingTimeInterval(60 * 60 * 24 * 3),
                    metric: .init(
                        value: 2,
                        unit: HKUnit.meterUnit(with: .kilo),
                        measurement: .walkRunDistance
                    ),
                    vitalKind: .cardioFitness
                )
            )
        }
    }
    .listStyle(.plain)
}
