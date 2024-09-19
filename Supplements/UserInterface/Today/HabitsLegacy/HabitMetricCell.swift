//
//  HabitMetricCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-09.
//

import SwiftUI

struct HabitMetricCell: View {
    let habitMetric: HabitModel.MeasurementMetric
    let isSelected: Bool

    var body: some View {
        HStack {
            Image(systemName: habitMetric.systemImage)
                .font(.title)
                .foregroundStyle(habitMetric.color)
                .frame(width: 40)

            Text(habitMetric.name)
                .bold()

            Spacer()

            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(habitMetric.color)
            }
        }
        .contentShape(Rectangle())
        .frame(height: 50)
    }
}

#Preview {
    List {
        HabitMetricCell(habitMetric: .stepCount, isSelected: true)
        HabitMetricCell(habitMetric: .waterIntake, isSelected: false)
    }
}
