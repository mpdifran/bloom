//
//  HabitCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-09.
//

import SwiftUI
import HealthKit

struct HabitCellLegacy: View {
    let habit: HabitModel

    var body: some View {
        HStack {
            Image(systemName: habit.systemImage)
                .font(.title)
                .foregroundStyle(habit.color)
                .frame(width: 40)

            Text(habit.name)
                .bold()

            Spacer()

            Text(habit.targetDisplayString)
                .font(.subheadline)
                .bold()
                .fontDesign(.rounded)
                .foregroundStyle(habit.color)
        }
    }
}

#Preview {
    List {
        HabitCellLegacy(
            habit: .init(
                measurement: .stepCount,
                value: 10000
            )
        )
        HabitCellLegacy(
            habit: .init(
                measurement: .waterIntake,
                value: 500
            )
        )
    }
}
