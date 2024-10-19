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

    @State private var showConfetti = 0

    init(habit: Habit) {
        self.habit = habit
        self._viewModel = ObservedObject(wrappedValue: HabitDailyUpdateCellViewModel(habit: habit))
    }

    var body: some View {
        HStack {
            CompletionCheckmarkView(state: viewModel.goalCompletionState)

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
                            .fontDesign(.rounded)
                    }
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
                        .animation(.default, value: viewModel.dailyValue)

                    Spacer()

                    Text(habit.displayQuantity)
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
                .bold()
            }

            DisclosureIndicator()
                .padding(.leading)
        }
        .cardContainer()
        .tint(habit.targetMetric.color)
        .standardConfetti(
            $showConfetti,
            colors: [
                habit.targetMetric.color,
                habit.targetMetric.color.darker(),
                habit.targetMetric.color.lighter()
            ]
        )
        .animation(.default, value: viewModel.dailyValue)
        .onShow {
            guard viewModel.shouldShowConfetti else { return }

            showConfetti += 1
            viewModel.shouldShowConfetti = false
        }
    }
}

#Preview {
    ScrollView {
        VStack {
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
            HabitDailyUpdateCell(
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
        .padding()
    }
    .groupedBackground()
}
