//
//  HabitCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-09.
//

import SwiftUI
import HealthKit

struct HabitCell: View {
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
        HabitCell(
            habit: .init(
                measurement: .stepCount,
                value: 10000
            )
        )
        HabitCell(
            habit: .init(
                measurement: .waterIntake,
                value: 500
            )
        )
    }
}
