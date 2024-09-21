//
//  HabitDailyUpdateCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-19.
//

import SwiftUI
import DataContainer
import HealthKit

struct HabitDailyUpdateCell: View {
    let habit: Habit

    @ObservedObject private var viewModel: HabitDailyUpdateCellViewModel

    init(habit: Habit) {
        self.habit = habit
        self._viewModel = ObservedObject(wrappedValue: HabitDailyUpdateCellViewModel(habit: habit))
    }

    var body: some View {
        HStack {
            CompletionCheckmarkView(hasCompleted: viewModel.hasCompletedTodayGoal)

            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: habit.targetMetric.systemImage)
                        .font(.title2)
                        .foregroundStyle(.tint)
                        .frame(width: 25)

                    VStack(alignment: .leading) {
                        if let vitalKind = habit.vitalKind {
                            Label(vitalKind.name, systemImage: vitalKind.systemImage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Text(habit.targetMetric.name)
                            .bold()
                    }
                }

                ProgressBar(progress: viewModel.dailyValue / habit.value)

                HStack {
                    Text("\(viewModel.dailyValue.format(using: .oneDecimalPlace)) \(habit.unit.unitString)")
                        .foregroundStyle(.tint)
                        .contentTransition(.numericText(value: viewModel.dailyValue))
                        .animation(.default, value: viewModel.dailyValue)

                    Spacer()

                    Text("\(NumberFormatter.noDecimalPlaces.string(for: habit.value) ?? "") \(habit.unit.unitString)")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
                .bold()
            }

            Image(systemName: "chevron.forward")
                .foregroundStyle(.secondary)
                .padding(.leading)
        }
        .tint(habit.targetMetric.color)
        .cardContainer()
        .animation(.default, value: viewModel.dailyValue)
    }
}

#Preview {
    ScrollView {
        HabitDailyUpdateCell(
            habit: .init(
                targetMetric: .timeInDaylight,
                value: 30,
                unitString: HKUnit.minute().unitString,
                startDate: .now,
                isSuggested: true,
                isUserEdited: false,
                vitalKind: .sleepQuality
            )
        )
        .padding()
    }
    .groupedBackground()
}
