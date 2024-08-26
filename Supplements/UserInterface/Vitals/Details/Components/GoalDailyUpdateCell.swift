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
                }
                .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                VStack(alignment: .trailing) {
                    Text("\(currentValue.format(to: 1)) \(goal.metric.unit.unitString)")
                        .font(.headline)
                        .bold()

                    if let remainingGoalValue {
                        Text("/ \(remainingGoalValue.format(to: 1)) \(goal.metric.unit.unitString)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if shouldShowChart {
                chart
            }
            predictiveTextView
        }
        .reload(after: 5)
        .animation(.bouncy, value: currentValue)
        .tint(goal.metric.measurement.color)
        .cardContainer(fill: .background.secondary)
        .task {
            await loadQuantity()
        }
    }
}

private extension GoalDailyUpdateCell {

    var chart: some View {
        Chart {
            BarMark(
                x: .value("Amount", currentValue),
                y: .value("Day", "Today")
            )
            .foregroundStyle(.tint)
            .cornerRadius(5)

            if let remainingGoalValue {
                RuleMark(
                    x: .value("Daily Goal", remainingGoalValue)
                )
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [2]))
                .foregroundStyle(currentValue < remainingGoalValue ? AnyShapeStyle(.tint) : AnyShapeStyle(.background.secondary))

                if goal.metric.measurement.isDecrease {
                    RectangleMark(
                        xStart: .value("Goal", remainingGoalValue),
                        xEnd: .value("", remainingGoalValue / 1.5)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                goal.metric.measurement.color.opacity(0.3),
                                .clear
                            ],
                            startPoint: .trailing,
                            endPoint: .leading
                        )
                    )
                } else {
                    RectangleMark(
                        xStart: .value("Goal", remainingGoalValue),
                        xEnd: .value("", remainingGoalValue * 1.3)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                goal.metric.measurement.color.opacity(0.3),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                }
            }
        }
        .chartXScale(domain: 0...maxChartValue * 1.3, range: .plotDimension)
        .frame(height: 60)
    }

    @ViewBuilder
    var predictiveTextView: some View {
        if let predictiveText {
            HStack {
                if hasMetGoal {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white, goal.metric.measurement.color)
                }
                Text(predictiveText)
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private extension GoalDailyUpdateCell {

    var remainingGoalValue: Double? {
        let startOfDay = Calendar.current.startOfDay(for: .now)

        guard let remainingHours = Calendar.current.dateComponents([.hour], from: startOfDay, to: goal.dueDate).hour else {
            return nil
        }

        let remainingGoalAmount = goal.metric.value - thisWeekValue
        if remainingGoalAmount < 0 {
            return nil
        }
        let rate = remainingGoalAmount / Double(remainingHours)
        return rate * 24
    }

    var remainingGoalValueNonOptional: Double {
        remainingGoalValue ?? goal.metric.value / 7
    }

    var maxChartValue: Double {
        max(currentValue, remainingGoalValueNonOptional)
    }

    var hasMetGoal: Bool {
        !goal.metric.measurement.isDecrease && thisWeekValue + currentValue > goal.metric.value
    }

    var shouldShowChart: Bool {
        thisWeekValue + currentValue < goal.metric.value
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
        if goal.metric.measurement.isDecrease {
            if thisWeekValue + currentValue > goal.metric.value {
                return "You've exceeded your goal for the week."
            }

            if
                let startOfWeek = Calendar.current.startOfWeek(for: .now),
                let hoursThisWeek = Calendar.current.dateComponents([.hour], from: startOfWeek, to: .now).hour,
                let remainingHours = Calendar.current.dateComponents([.hour], from: .now, to: goal.dueDate).hour
            {
                let rate = (thisWeekValue + currentValue) / Double(hoursThisWeek)
                let remainingGoalAmount = goal.metric.value - (thisWeekValue + currentValue)
                let projectedHours = remainingGoalAmount / rate

                if projectedHours < Double(remainingHours) {
                    if currentValue > remainingGoalValueNonOptional {
                        let tomorrow = Calendar.current.startOfTomorrow(for: .now)

                        if let tomorrowRemainingHours = Calendar.current.dateComponents([.hour], from: tomorrow, to: goal.dueDate).hour {
                            let tomorrowRate = remainingGoalAmount / Double(tomorrowRemainingHours)
                            let tomorrowDailyRate = tomorrowRate * 24

                            return "At this rate, you're going to exceed your weekly goal by the end of the week! Since you've exceeded your goal today, you need to reduce to \(tomorrowDailyRate.format(to: 1)) \(goal.metric.unit.unitString) tomorrow to meet your weekly goal."
                        }
                    }

                    guard let projectedDate = Calendar.current.date(byAdding: .hour, value: Int(projectedHours), to: .now) else {
                        return "At this rate, you're going to exceed your weekly goal by the end of the week! Reduce to \(remainingGoalValueNonOptional.format(to: 1)) \(goal.metric.unit.unitString) today to meet your weekly goal."
                    }

                    return "At this rate, you're going to exceed your weekly goal by \(DateFormatter.justDayOfWeek.string(from: projectedDate))! Reduce to \(remainingGoalValueNonOptional.format(to: 1)) \(goal.metric.unit.unitString) today to meet your weekly goal."
                } else {
                    if currentValue > remainingGoalValueNonOptional {
                        return "Looks like you've exceeded your goal today. Let's try again tomorrow!"
                    }
                    return "If you keep it below \(remainingGoalValueNonOptional.format(to: 1)) \(goal.metric.unit.unitString) today, you'll meet your weekly goal!"
                }
            }
        } else {
            if thisWeekValue > goal.metric.value {
                return "You've reached your weekly goal!"
            }

            if 
                let startOfWeek = Calendar.current.startOfWeek(for: .now),
                let hoursThisWeek = Calendar.current.dateComponents([.hour], from: startOfWeek, to: .now).hour,
                let remainingHours = Calendar.current.dateComponents([.hour], from: .now, to: goal.dueDate).hour
            {
                let rate = thisWeekValue / Double(hoursThisWeek)
                let remainingGoalAmount = goal.metric.value - (thisWeekValue + currentValue)
                let projectedHours = remainingGoalAmount / rate

                if projectedHours < Double(remainingHours) {
                    guard let projectedDate = Calendar.current.date(byAdding: .hour, value: Int(projectedHours), to: .now) else {
                        return "At this rate, you'll hit your weekly goal by the end of the week!"
                    }

                    return "At this rate, you'll hit your weekly goal by \(DateFormatter.justDayOfWeek.string(from: projectedDate))!"
                } else {
                    if currentValue > remainingGoalValueNonOptional {
                        return "Keep up the pace to hit your weekly goal by the end of the week!"
                    }

                    return "At this pace, you won't hit your weekly goal in time! Try and get to \(remainingGoalValueNonOptional.format(to: 1)) \(goal.metric.unit.unitString) today to hit your weekly goal."
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
