//
//  GoalDailyUpdateCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-14.
//

import SwiftUI
import Charts
import HealthKit

@MainActor
struct GoalDailyUpdateCell: View {
    let goal: GoalModel

    @StateObject private var viewModel: GoalDailyUpdateCellViewModel

    init(goal: GoalModel) {
        self.goal = goal
        self._viewModel = StateObject(wrappedValue: GoalDailyUpdateCellViewModel(goal: goal))
    }

    var body: some View {
        HStack {
            CompletionCheckmarkView(hasCompleted: viewModel.hasCompletedTodayGoal)

            HStack {
                Image(systemName: goal.systemImage)
                    .foregroundStyle(.tint)
                    .font(.title)
                    .minimumScaleFactor(0.1)
                    .frame(width: 30)

                VStack(alignment: .leading) {
                    Label(goal.vitalKind.name, systemImage: goal.vitalKind.systemImage)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(goal.title)
                        .bold()

                    if goal.metric.measurement.isDecrease {
                        ProgressView(value: min(remainingValue / goalValue, 1))
                            .scaleEffect(x: -1)
                            .foregroundStyle(.tint)
                    } else {
                        ProgressView(value: min(viewModel.dailyValue / goalValue, 1))
                            .foregroundStyle(.tint)
                    }

                    Group {
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
                            HStack {
                                Text("\(viewModel.dailyValue.format(using: .oneDecimalPlace)) \(goal.metric.unit.unitString)")
                                    .foregroundStyle(.tint)
                                    .contentTransition(.numericText(value: viewModel.dailyValue))

                                Text("/ \(goalValue.format(using: .oneDecimalPlace)) \(goal.metric.unit.unitString)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .font(.subheadline)
                    .bold()
                }
                .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }

            Image(systemName: "chevron.forward")
                .foregroundStyle(.secondary)
                .padding(.leading)
        }
        .tint(goal.metric.measurement.color)
        .cardContainer()
        .animation(.easeOut, value: viewModel.dailyValue)
        .standardConfetti(
            $viewModel.didHitGoal,
            colors: [
                goal.metric.measurement.color,
                .white,
                goal.metric.measurement.color.lighter(),
                goal.metric.measurement.color.darker()
            ]
        )
        .onAppear {
            viewModel.checkHitGoal()
        }
    }
}

@MainActor
private extension GoalDailyUpdateCell {

    var remainingValue: Double {
        goalValue - viewModel.dailyValue
    }

    var goalValue: Double {
        (goal.metric.value / 7)
    }
}

#Preview {
    ScrollView {
        VStack {
            GoalDailyUpdateCell(
                goal: .init(
                    title: "Walking + Running Distance",
                    systemImage: "figure.walk",
                    summary: "Walking and running are good for you.",
                    dueDate: .now.addingTimeInterval(60 * 60 * 24 * 3),
                    metric: .init(
                        value: 21,
                        unit: HKUnit.meterUnit(with: .kilo),
                        measurement: .walkRunDistance
                    ),
                    vitalKind: .cardioFitness
                )
            )

            GoalDailyUpdateCell(
                goal: .init(
                    title: "Sodium Intake",
                    systemImage: "arrow.down.circle",
                    summary: "Eat less sodium.",
                    dueDate: .now.addingTimeInterval(60 * 60 * 24 * 3),
                    metric: .init(
                        value: 15,
                        unit: .gram(),
                        measurement: .decreaseSodium
                    ),
                    vitalKind: .nutrition
                )
            )
        }
        .padding()
    }
    .gradientRootBackground()
}
