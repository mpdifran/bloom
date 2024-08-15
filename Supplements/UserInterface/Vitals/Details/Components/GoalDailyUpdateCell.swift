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

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
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
                Spacer(minLength: 0)
            }

            Chart {
                BarMark(x: .value("Amount", currentValue))
                    .foregroundStyle(.tint)
                    .cornerRadius(5)
                    .annotation(position: .overlay, alignment: .leading) {
                        Text("\(currentValue.format()) \(goal.metric.unit.unitString)")
                            .font(.caption)
                            .bold()
                            .foregroundStyle(.tint)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 1)
                            .background {
                                Capsule()
                                    .fill(.background.secondary)
                            }
                    }
            }
            .chartXScale(domain: 0...currentValue * 1.3, range: .plotDimension)
            .frame(height: 40)
        }
        .tint(goal.metric.measurement.color)
        .cardContainer(fill: .background.secondary)
        .task {
            await loadQuantity()
        }
    }
}

private extension GoalDailyUpdateCell {

    func loadQuantity() async {
        let quantity = await goal.metric.quantity(for: .trailingHoursFromNow(.numTrailingHours))
        await MainActor.run {
            self.currentValue = quantity.doubleValue(for: goal.metric.unit)
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
