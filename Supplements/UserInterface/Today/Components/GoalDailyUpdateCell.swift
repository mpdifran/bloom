//
//  GoalDailyUpdateCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-14.
//

import SwiftUI
import Charts
import HealthKit

struct GoalDailyUpdateCell: View {
    let goal: GoalModel

    @State private var currentValue: Double = 0
    @State private var thisWeekValue: Double = 0

    @State private var observationHandler: HKObserverQueryHandle?

    init(goal: GoalModel) {
        self.goal = goal

        observeGoalMetric()
    }

    var body: some View {
        HStack {
            Group {
                if hasCompletedTodayGoal {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white, goal.metric.measurement.color)
                } else {
                    Image(systemName: "circle")
                        .foregroundStyle(goal.metric.measurement.color)
                }
            }
            .font(.title2)

            HStack {
                VStack(alignment: .leading) {
                    Text(goal.title)
                        .bold()

                    HStack {
                        Text("\(currentValue.format(to: 1)) \(goal.metric.unit.unitString)")
                            .foregroundStyle(.tint)

                        Text("/ \(remainingGoalValue.format(to: 1)) \(goal.metric.unit.unitString)")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                    .bold()

                    ProgressView(value: currentValue / remainingGoalValue)
                        .foregroundStyle(.tint)
                }
                .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                Image(systemName: goal.systemImage)
                    .font(.largeTitle)
                    .foregroundStyle(.tint)
            }
        }
        .tint(goal.metric.measurement.color)
        .cardContainer(fill: .background.secondary)
        .task {
            await loadQuantity()
        }
    }
}

private extension GoalDailyUpdateCell {

    var hasCompletedTodayGoal: Bool {
        guard !goal.metric.measurement.isDecrease else { return false }

        return currentValue > (goal.metric.value / 7)
    }
}

private extension GoalDailyUpdateCell {

    var remainingGoalValue: Double {
        (goal.metric.value / 7)
    }

    var maxChartValue: Double {
        max(currentValue, remainingGoalValue)
    }

    var hasMetGoal: Bool {
        !goal.metric.measurement.isDecrease && thisWeekValue + currentValue > goal.metric.value
    }

    var shouldShowChart: Bool {
        thisWeekValue + currentValue < goal.metric.value
    }

    func observeGoalMetric() {
        observationHandler = HealthManager.shared.healthStore.observeChanges(
            sampleTypes: goal.metric.measurement.sampleTypes,
            dateRange: .mondayMorningToNow(),
            frequency: .immediate
        ) {
            await loadQuantity()
        }
    }

    func loadQuantity() async {
        let quantity = await goal.metric.quantity(for: .startOfDayToNow())
        let thisWeekQuantity = await goal.metric.quantity(for: .mondayMorningToStartOfToday())
        await MainActor.run {
            self.currentValue = quantity.doubleValue(for: goal.metric.unit)
            self.thisWeekValue = thisWeekQuantity.doubleValue(for: goal.metric.unit)
        }
    }
}

#Preview {
    ScrollView {
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
        .padding()
    }
}
