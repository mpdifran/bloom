//
//  EveningHabitProgressCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-06.
//

import SwiftUI
import HealthKit
import DataContainer

struct EveningHabitProgressCell: View {
    let habit: Habit

    @StateObject private var viewModel: HabitDailyUpdateCellViewModel

    init(habit: Habit) {
        self.habit = habit
        self._viewModel = StateObject(wrappedValue: HabitDailyUpdateCellViewModel(habit: habit))
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: habit.targetMetric.systemImage)
                        .font(.title)
                        .foregroundStyle(.tint)
                        .minimumScaleFactor(0.1)
                        .frame(width: 30)

                    VStack(alignment: .leading) {
                        if let vitalKind = habit.vitalKind {
                            HStack {
                                Image(systemName: vitalKind.systemImage)
                                Text(vitalKind.name)
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }

                        Text(habit.targetMetric.name)
                            .font(.title3)
                            .bold()
                    }

                    Spacer()
                }

                ProgressBar(
                    value: viewModel.dailyValue,
                    target: habit.value,
                    measurementStyle: habit.targetMetric.measurementStyle == .range ? .range : .minimum
                )

                HStack {
                    Text(viewModel.formattedDailyValue)
                        .foregroundStyle(.tint)
                        .contentTransition(.numericText(value: viewModel.dailyValue))

                    Spacer()

                    Text(habit.displayQuantity)
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
                .bold()
            }

            Spacer()

            CompletionCheckmarkView(hasCompleted: viewModel.hasCompletedTodayGoal)

            Image(systemName: "chevron.forward")
                .foregroundStyle(.secondary)
        }
        .tint(habit.targetMetric.color)
        .animation(.easeOut, value: viewModel.dailyValue)
        .cardContainer(fill: .background.secondary)
    }
}

#Preview {
    List {
        Section("Focus Areas") {
            EveningHabitProgressCell(
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
            EveningHabitProgressCell(
                habit: .init(
                    targetMetric: .calories,
                    value: 1800,
                    unitString: HKUnit.largeCalorie().unitString,
                    startDate: .now,
                    isSuggested: true,
                    isUserEdited: false,
                    vitalKind: .nutrition
                )
            )
        }
    }
    .listStyle(.plain)
}
