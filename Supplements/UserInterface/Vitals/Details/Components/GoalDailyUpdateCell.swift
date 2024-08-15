//
//  GoalDailyUpdateCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-14.
//

import SwiftUI
import Charts
import HealthKit

private extension Int {
    static let numTrailingHours: Int = 24
}

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
                    Text("Past \(Int.numTrailingHours) hours")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                Text("\(currentValue.format(to: 1)) \(goal.metric.unit.unitString)")
                    .font(.headline)
                    .bold()
            }

            Group {
                if currentValue < 0.0001 {
                    Text("No Data")
                        .foregroundStyle(.secondary)
                        .bold()
                        .horizontallyCentered()
                } else {
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
            }
            .frame(height: 40)

            if let predictiveText {
                TimelineView(.periodic(from: .now, by: 60 * 60)) { _ in
                    Text(predictiveText)
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
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
        guard let remainingHours = Calendar.current.dateComponents([.hour], from: .now, to: goal.dueDate).hour else {
            return goal.metric.value / 7
        }

        let remainingGoalAmount = goal.metric.value - thisWeekValue
        if remainingGoalAmount < 0 {
            return goal.metric.value / 7
        }
        let rate = remainingGoalAmount / Double(remainingHours)
        return rate * Double(Int.numTrailingHours)
    }

    var maxChartValue: Double {
        max(currentValue, remainingGoalValue)
    }

    func loadQuantity() async {
        let quantity = await goal.metric.quantity(for: .trailingHoursFromNow(.numTrailingHours))
        let thisWeekQuantity = await goal.metric.quantity(for: .startOfWeekToNow())
        await MainActor.run {
            self.currentValue = quantity.doubleValue(for: goal.metric.unit)
            self.thisWeekValue = thisWeekQuantity.doubleValue(for: goal.metric.unit)
        }
    }

    var predictiveText: String? {
        if goal.metric.measurement.isDecrease {
            if thisWeekValue > goal.metric.value {
                return "You've exceeded your goal for the week."
            } else if let remainingHours = Calendar.current.dateComponents([.hour], from: .now, to: goal.dueDate).hour {
                let rate = currentValue / Double(Int.numTrailingHours)
                let remainingGoalAmount = goal.metric.value - thisWeekValue
                let projectedHours = remainingGoalAmount / rate

                if projectedHours < Double(remainingHours) {
                    guard let projectedDate = Calendar.current.date(byAdding: .hour, value: Int(projectedHours), to: .now) else {
                        return nil
                    }
                    let requiredPace = remainingGoalAmount / Double(remainingHours)
                    let requiredTimeWindowPace = requiredPace * Double(Int.numTrailingHours)

                    return "At this rate, you're going to exceed your goal by \(DateFormatter.justDayOfWeek.string(from: projectedDate))! Reduce to \(requiredTimeWindowPace.format(to: 1)) \(goal.metric.unit.unitString) per \(Int.numTrailingHours) hours to meet your goal."
                } else {
                    return "At this pace, you'll meet your goal!"
                }
            }
        } else {
            if currentValue < 0.0001 {
                return "You haven't made any progress in the last 24 hours."
            } else if thisWeekValue > goal.metric.value {
                return "You've reached your goal!"
            } else if let remainingHours = Calendar.current.dateComponents([.hour], from: .now, to: goal.dueDate).hour {
                let rate = currentValue / Double(Int.numTrailingHours)
                let remainingGoalAmount = goal.metric.value - thisWeekValue
                let projectedHours = remainingGoalAmount / rate

                if projectedHours < Double(remainingHours) {
                    guard let projectedDate = Calendar.current.date(byAdding: .hour, value: Int(projectedHours), to: .now) else {
                        return nil
                    }

                    return "At this rate, you'll hit your goal by \(DateFormatter.justDayOfWeek.string(from: projectedDate))!"
                } else {
                    let requiredPace = remainingGoalAmount / Double(remainingHours)
                    let requiredTimeWindowPace = requiredPace * Double(Int.numTrailingHours)

                    return "At this pace, you won't hit your goal in time! Try and get to \(requiredTimeWindowPace.format(to: 1)) \(goal.metric.unit.unitString) per \(Int.numTrailingHours) hours to hit your goal."
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
