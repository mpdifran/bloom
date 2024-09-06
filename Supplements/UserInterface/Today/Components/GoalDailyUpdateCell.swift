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
                    .font(.largeTitle)
                    .minimumScaleFactor(0.1)
                    .frame(width: 40)

                VStack(alignment: .leading) {
                    Label(goal.vitalKind.name, systemImage: goal.vitalKind.systemImage)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(goal.title)
                        .bold()

                    ProgressView(value: min(viewModel.dailyValue / remainingGoalValue, 1))
                        .foregroundStyle(.tint)

                    HStack {
                        Text("\(viewModel.dailyValue.format(to: 1)) \(goal.metric.unit.unitString)")
                            .foregroundStyle(.tint)

                        Text("/ \(remainingGoalValue.format()) \(goal.metric.unit.unitString)")
                            .foregroundStyle(.secondary)
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
    }
}

private extension GoalDailyUpdateCell {

    var remainingGoalValue: Double {
        (goal.metric.value / 7)
    }
}

#Preview {
    ScrollView {
        VStack {
            GoalDailyUpdateCell(
                goal: .init(
                    title: "Increase Walking + Running Distance",
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
        .padding()
    }
    .gradientRootBackground()
}
