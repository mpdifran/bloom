//
//  UserAddedHabitCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-21.
//

import SwiftUI
import DataContainer
import HealthKit

struct UserAddedHabitCell: View {
    let habit: Habit

    var body: some View {
        HStack {
            Image(systemName: habit.targetMetric.systemImage)
                .font(.title)
                .foregroundStyle(habit.targetMetric.color)
                .frame(width: 40)

            Text(habit.targetMetric.name)
                .bold()

            Spacer()

            Text(habit.displayQuantity)
                .font(.subheadline)
                .bold()
                .fontDesign(.rounded)
                .foregroundStyle(habit.targetMetric.color)
        }
    }
}

#Preview {
    UserAddedHabitCell(
        habit: .init(
            targetMetric: .walkingRunningDistance,
            value: 5,
            unitString: HKUnit.meterUnit(with: .kilo).unitString,
            startDate: .now,
            isSuggested: false,
            isUserEdited: true
        )
    )
}
