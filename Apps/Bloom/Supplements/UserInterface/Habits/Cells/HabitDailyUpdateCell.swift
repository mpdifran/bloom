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
            IconGauge(
                progress: viewModel.dailyValue / habit.value,
                dimension: 50,
                lineThickness: 8,
                systemImage: viewModel.goalCompletionState == .metGoal ? "checkmark" : habit.targetMetric.systemImage,
                color: habit.targetMetric.color
            )
            .bold()
            .foregroundStyle(viewModel.goalCompletionState == .metGoal ? habit.targetMetric.color : .text)
            .background {
                if viewModel.goalCompletionState == .metGoal {
                    Circle()
                        .fill(habit.targetMetric.color.tertiary)
                }
            }

            VStack(alignment: .leading) {
                HStack {
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

                    Spacer(minLength: 0)

                    VStack(alignment: .trailing) {
                        Text(viewModel.formattedDailyValue)
                            .font(.title3)
                            .fontDesign(.rounded)
                            .foregroundStyle(.tint)
                            .bold()
                            .contentTransition(.numericText(value: viewModel.dailyValue))
                            .animation(.default, value: viewModel.dailyValue)

                        Text("/ \(habit.displayQuantity)")
                            .font(.caption)
                            .bold()
                            .foregroundStyle(.secondary)
                            .fontDesign(.rounded)
                    }
                }
            }

            Spacer(minLength: 0)

            DisclosureIndicator()
                .padding(.leading)
        }
        .cardContainer(fill: .background)
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
