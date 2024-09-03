//
//  GoalDetailsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-02.
//

import SwiftUI
import HealthKit
import Charts
import AppUI

struct GoalDetailsView: View {

    @StateObject private var viewModel: GoalDetailsViewModel

    @ObservedObject private var vitalsViewModel = VitalsViewModel.shared

    init(goals: Binding<[GoalModel]>) {
        self._viewModel = StateObject(wrappedValue: GoalDetailsViewModel(goals: goals))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    Image(systemName: goal.systemImage)
                        .font(.largeTitle)
                        .foregroundStyle(goal.metric.measurement.color)

                    Text(goal.title)
                        .font(.title3)
                        .bold()

                    Spacer(minLength: 0)

                    Text(goal.metric.targetQuantity.displayString(for: goal.metric.unit))
                        .bold()
                        .fontDesign(.rounded)
                        .foregroundStyle(goal.metric.measurement.color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background {
                            Capsule()
                                .fill(.fill)
                        }
                }

                chart

                goalDescriptionCardView

                goalPickerMenu
            }
            .padding()
        }
        .navigationTitle("Goal")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.default, value: viewModel.goal)
    }
}

private extension GoalDetailsView {

    var goal: GoalModel {
        viewModel.goal
    }

    var targetVitalModel: VitalModel? {
        vitalsViewModel.vitals.first(where: { $0.id == goal.vitalKind })
    }

    var cumulativeSamples: [DateQuantitySample] {
        var runningTotal: Double = 0
        var result = [DateQuantitySample]()

        for sample in viewModel.dailyQuantities {
            let sampleValue = sample.quantity.doubleValue(for: goal.metric.unit)
            let newTotal = runningTotal + sampleValue

            result.append(DateQuantitySample(date: sample.date, quantity: .init(unit: goal.metric.unit, doubleValue: newTotal)))

            runningTotal += sampleValue
        }

        return result
    }

    var chartStartDate: Date {
        Calendar.current.mondayMorningMidnight(for: .now) ?? .now
    }

    var chartEndDate: Date {
        Calendar.current.nextMondayMorningMidnight(for: .now) ?? .now
    }

    var cumulativeChart: some View {
        Chart {
            LineMark(
                x: .value("Date", chartStartDate),
                y: .value("Value", 0)
            )
            .lineStyle(StrokeStyle(lineWidth: 4, lineCap: .round))
            .foregroundStyle(by: .value("DataSet", "Past Line"))

            AreaMark(
                x: .value("Date", chartStartDate),
                y: .value("Value", 0)
            )
            .foregroundStyle(goal.metric.measurement.color.opacity(0.5))

            ForEach(cumulativeSamples) { sample in
                LineMark(
                    x: .value("Date", sample.date, unit: .day),
                    y: .value("Value", sample.quantity.doubleValue(for: goal.metric.unit))
                )
                .lineStyle(StrokeStyle(lineWidth: 4, lineCap: .round))
                .foregroundStyle(by: .value("DataSet", "Past Line"))

                AreaMark(
                    x: .value("Date", sample.date, unit: .day),
                    y: .value("Value", sample.quantity.doubleValue(for: goal.metric.unit))
                )
                .foregroundStyle(goal.metric.measurement.color.opacity(0.5))
            }

            if
                let projectedEndQuantity = viewModel.projectedEndQuantity,
                let lastSample = cumulativeSamples.last
            {
                LineMark(
                    x: .value("Date", lastSample.date, unit: .day),
                    y: .value("Value", lastSample.quantity.doubleValue(for: goal.metric.unit))
                )
                .foregroundStyle(by: .value("DataSet", "Future Line"))
                .lineStyle(StrokeStyle(lineWidth: 4, lineCap: .round, dash: [5, 10]))
                LineMark(
                    x: .value("Date", chartEndDate),
                    y: .value("Value", projectedEndQuantity.doubleValue(for: goal.metric.unit))
                )
                .foregroundStyle(by: .value("DataSet", "Future Line"))
                .lineStyle(StrokeStyle(lineWidth: 4, lineCap: .round, dash: [5, 10]))

                PointMark(
                    x: .value("Date", lastSample.date, unit: .day),
                    y: .value("Value", lastSample.quantity.doubleValue(for: goal.metric.unit))
                )
                .foregroundStyle(.text)
            }

            RuleMark(
                y: .value("Goal", goal.metric.value)
            )
            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
            .foregroundStyle(goal.metric.measurement.color.opacity(0.5))

            if goal.metric.measurement.isDecrease {
                RectangleMark(
                    yStart: .value("Goal", goal.metric.value),
                    yEnd: .value("", goal.metric.value / 1.5)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            goal.metric.measurement.color.opacity(0.3),
                            .clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            } else {
                RectangleMark(
                    yStart: .value("Goal", goal.metric.value),
                    yEnd: .value("", goal.metric.value * 1.3)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            goal.metric.measurement.color.opacity(0.3),
                            .clear
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
            }
        }
        .chartForegroundStyleScale([
            "Past Line" : goal.metric.measurement.color,
            "Future Line" : goal.metric.measurement.color
        ])
        .chartLegend(.hidden)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisGridLine()
                AxisTick()
                if let date = value.as(Date.self) {
                    AxisValueLabel(DateFormatter.justDayOfWeekShort.string(from: date))
                } else {
                    AxisValueLabel()
                }
            }
        }
        .chartXScale(domain: chartStartDate...chartEndDate, range: .plotDimension)
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisTick()

                if let doubleValue = value.as(Double.self) {
                    AxisValueLabel {
                        Text("\(doubleValue.format()) \(goal.metric.unitString)")
                    }
                } else {
                    AxisValueLabel()
                }
            }
        }
        .frame(height: 220)
        .tint(goal.metric.measurement.color)
    }

    var barChart: some View {
        Chart {
            ForEach(viewModel.dailyQuantities) { sample in
                BarMark(
                    x: .value("Date", sample.date, unit: .day),
                    y: .value("Value", sample.quantity.doubleValue(for: goal.metric.unit))
                )
                .foregroundStyle(.tint)
            }

            RuleMark(
                y: .value("Goal", goal.metric.dailyValue)
            )
            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
            .foregroundStyle(goal.metric.measurement.color.opacity(0.5))

            if goal.metric.measurement.isDecrease {
                RectangleMark(
                    yStart: .value("Goal", goal.metric.dailyValue),
                    yEnd: .value("", goal.metric.dailyValue / 1.5)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            goal.metric.measurement.color.opacity(0.3),
                            .clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            } else {
                RectangleMark(
                    yStart: .value("Goal", goal.metric.dailyValue),
                    yEnd: .value("", goal.metric.dailyValue * 1.3)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            goal.metric.measurement.color.opacity(0.3),
                            .clear
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisGridLine()
                AxisTick()
                if let date = value.as(Date.self) {
                    AxisValueLabel(DateFormatter.justDayOfWeekShort.string(from: date))
                } else {
                    AxisValueLabel()
                }
            }
        }
        .chartXScale(domain: chartStartDate...chartEndDate, range: .plotDimension)
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisTick()

                if let doubleValue = value.as(Double.self) {
                    AxisValueLabel {
                        Text("\(doubleValue.format()) \(goal.metric.unitString)")
                    }
                } else {
                    AxisValueLabel()
                }
            }
        }
        .frame(height: 220)
        .tint(goal.metric.measurement.color)
    }

    @ViewBuilder
    var chart: some View {
        if goal.metric.measurement.isCumulative {
            cumulativeChart
        } else {
            barChart
        }
    }

    var goalDescriptionCardView: some View {
        DetailInfoCardView {
            Text(goal.summary)

            if let targetVitalModel {
                TargetVitalComponentView(vital: targetVitalModel)
            }
        }
    }

    @ViewBuilder
    var goalPickerMenu: some View {
        if viewModel.allGoals.count > 1 {
            Menu {
                ForEachEnumerated(viewModel.allGoals) { (goalIndex, goal) in
                    if goalIndex > 0 {
                        Button(goal.title, systemImage: goal.systemImage) {
                            viewModel.selectGoal(at: goalIndex)
                        }
                    }
                }
            } label: {
                LabeledContent("Change Goal") {
                    Image(systemName: "trophy")
                        .foregroundStyle(goal.metric.measurement.color)
                }
            }
            .buttonStyle(.plain)
            .cardContainer(fill: .background.secondary)
        }
    }
}

#Preview {
    struct PreviewView: View {
        @State private var goals: [GoalModel] = [
            GoalModel(
                title: "Walking + Running Distance",
                systemImage: "figure.walk",
                summary: "An easy way to improve your activity level is to incorporate more walking and running into your week.",
                dueDate: .now.addingTimeInterval(
                    60 * 60 * 24 * 3
                ),
                metric: .init(
                    value: 25,
                    unit: HKUnit.meterUnit(
                        with: .kilo
                    ),
                    measurement: .walkRunDistance
                ),
                vitalKind: .cardioFitness
            ),
            GoalModel(
                title: "Eat Less Sodium",
                systemImage: "arrow.down.circle",
                summary: "You're getting too much sodium. Try avoiding eating things like processed meats, canned vegetables and soups, cheese, and avoid adding table salt to meals.",
                dueDate: .now.addingTimeInterval(
                    60 * 60 * 24 * 3
                ),
                metric: .init(
                    value: 24500,
                    unit: HKUnit.gramUnit(with: .milli),
                    measurement: .decreaseSodium
                ),
                vitalKind: .nutrition
            )
        ]

        var body: some View {
            NavigationView {
                GoalDetailsView(goals: $goals)
            }
        }
    }

    return PreviewView()
}
