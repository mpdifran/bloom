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

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                Image(systemName: goal.systemImage)
                    .font(.title2)
                    .foregroundStyle(.tint)

                VStack(alignment: .leading) {
                    Text(goal.title)
                        .bold()
                    Text("Today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                VStack(alignment: .trailing) {
                    Text("\(currentValue.format(to: 1)) \(goal.metric.unit.unitString)")
                        .font(.headline)
                        .bold()
                    Text("/ \(remainingGoalValue.format(to: 1)) \(goal.metric.unit.unitString)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Group {
                Chart {
                    BarMark(x: .value("Amount", currentValue))
                        .foregroundStyle(.tint)
                        .cornerRadius(5)

                    RuleMark(
                        x: .value("Daily Goal", remainingGoalValue)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [2]))
                    .foregroundStyle(currentValue < remainingGoalValue ? AnyShapeStyle(.tint) : AnyShapeStyle(.background.secondary))
                }
                .chartXScale(domain: 0...maxChartValue * 1.1, range: .plotDimension)
            }
            .frame(height: 40)

            if let predictiveText {
                Text(predictiveText)
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .reload(after: 60)
        .animation(.bouncy(duration: 1), value: currentValue)
        .tint(goal.metric.measurement.color)
        .cardContainer(fill: .background.secondary)
        .task {
            await loadQuantity()
        }
    }
}

private extension GoalDailyUpdateCell {

    var remainingGoalValue: Double {
        let startOfDay = Calendar.current.startOfDay(for: .now)

        guard let remainingHours = Calendar.current.dateComponents([.hour], from: startOfDay, to: goal.dueDate).hour else {
            return goal.metric.value / 7
        }

        let remainingGoalAmount = goal.metric.value - thisWeekValue
        if remainingGoalAmount < 0 {
            return goal.metric.value / 7
        }
        let rate = remainingGoalAmount / Double(remainingHours)
        return rate * 24
    }

    var maxChartValue: Double {
        max(currentValue, remainingGoalValue)
    }

    func loadQuantity() async {
        let quantity = await goal.metric.quantity(for: .startOfDayToNow())
        let thisWeekQuantity = await goal.metric.quantity(for: .startOfWeekToStartOfToday())
        await MainActor.run {
            self.currentValue = quantity.doubleValue(for: goal.metric.unit)
            self.thisWeekValue = thisWeekQuantity.doubleValue(for: goal.metric.unit)
        }
    }

    var predictiveText: String? {
        let startOfDay = Calendar.current.startOfDay(for: .now)

        if goal.metric.measurement.isDecrease {
            if thisWeekValue + currentValue > goal.metric.value {
                return "You've exceeded your goal for the week."
            }

            if
                let startOfWeek = Calendar.current.startOfWeek(for: .now),
                let hoursThisWeek = Calendar.current.dateComponents([.hour], from: startOfWeek, to: startOfDay).hour,
                let remainingHours = Calendar.current.dateComponents([.hour], from: startOfDay, to: goal.dueDate).hour
            {
                let rate = thisWeekValue / Double(hoursThisWeek)
                let remainingGoalAmount = goal.metric.value - thisWeekValue
                let projectedHours = remainingGoalAmount / rate

                if projectedHours < Double(remainingHours) {
                    if currentValue > remainingGoalValue {
                        let tomorrow = Calendar.current.startOfTomorrow(for: .now)

                        let currentRemainingAmount = remainingGoalAmount - currentValue

                        if let tomorrowRemainingHours = Calendar.current.dateComponents([.hour], from: tomorrow, to: goal.dueDate).hour {
                            let tomorrowRate = currentRemainingAmount / Double(tomorrowRemainingHours)
                            let tomorrowDailyRate = tomorrowRate * 24

                            return "At this rate, you're going to exceed your weekly goal by the end of the week! Since you've exceeded your goal today, you need to reduce to \(tomorrowDailyRate.format(to: 1)) \(goal.metric.unit.unitString) tomorrow to meet your weekly goal."
                        }
                    }

                    guard let projectedDate = Calendar.current.date(byAdding: .hour, value: Int(projectedHours), to: startOfDay) else {
                        return "At this rate, you're going to exceed your weekly goal by the end of the week! Reduce to \(remainingGoalValue.format(to: 1)) \(goal.metric.unit.unitString) today to meet your weekly goal."
                    }

                    return "At this rate, you're going to exceed your weekly goal by \(DateFormatter.justDayOfWeek.string(from: projectedDate))! Reduce to \(remainingGoalValue.format(to: 1)) \(goal.metric.unit.unitString) today to meet your weekly goal."
                } else {
                    return "If you keep it below \(remainingGoalValue.format(to: 1)) \(goal.metric.unit.unitString) today, you'll meet your weekly goal!"
                }
            }
        } else {
            if currentValue < 0.0001 {
                return "You haven't made any progress today."
            } else if thisWeekValue > goal.metric.value {
                return "You've reached your weekly goal!"
            }

            if 
                let startOfWeek = Calendar.current.startOfWeek(for: .now),
                let hoursThisWeek = Calendar.current.dateComponents([.hour], from: startOfWeek, to: startOfDay).hour,
                let remainingHours = Calendar.current.dateComponents([.hour], from: startOfDay, to: goal.dueDate).hour
            {
                let rate = thisWeekValue / Double(hoursThisWeek)
                let remainingGoalAmount = goal.metric.value - thisWeekValue
                let projectedHours = remainingGoalAmount / rate

                if projectedHours < Double(remainingHours) {
                    guard let projectedDate = Calendar.current.date(byAdding: .hour, value: Int(projectedHours), to: startOfDay) else {
                        return "At this rate, you'll hit your weekly goal by the end of the week!"
                    }

                    return "At this rate, you'll hit your weekly goal by \(DateFormatter.justDayOfWeek.string(from: projectedDate))!"
                } else {
                    return "At this pace, you won't hit your weekly goal in time! Try and get to \(remainingGoalValue.format(to: 1)) \(goal.metric.unit.unitString) today to hit your weekly goal."
                }
            }
        }

        return nil
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
