//
//  DebugHabitCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-23.
//

import SwiftUI
import DataContainer
import HealthKit

struct DebugHabitCell: View {
    let habit: Habit

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(habit.targetMetric.name)
                    .bold()
                Text(dateSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.leading)

            Spacer()

            VStack {
                Text(habit.displayQuantity)
                    .foregroundStyle(habit.targetMetric.color)
                    .bold()
                Text(habit.isSuggested ? "Suggested" : "User Added")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private extension DebugHabitCell {

    var dateSubtitle: String {
        let startDateString = DateFormatter.justDateLong.string(from: habit.startDate)
        let endDateString: String?
        if let endDate = habit.endDate {
            endDateString = DateFormatter.justDateLong.string(from: endDate)
        } else {
            endDateString = nil
        }

        return [startDateString, endDateString]
            .compactMap({ $0 })
            .joined(separator: " > ")
    }
}

#Preview {
    List {
        DebugHabitCell(
            habit: Habit(
                targetMetric: .stepCount,
                value: 3000,
                unitString: HKUnit.count().unitString,
                startDate: .now,
                isSuggested: true,
                isUserEdited: false
            )
        )
        DebugHabitCell(
            habit: Habit(
                targetMetric: .stepCount,
                value: 3000,
                unitString: HKUnit.count().unitString,
                startDate: .now.addingTimeInterval(133254523),
                endDate: .now,
                isSuggested: false,
                isUserEdited: true
            )
        )
    }
}
