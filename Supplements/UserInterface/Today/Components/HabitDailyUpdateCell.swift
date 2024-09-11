//
//  HabitDailyUpdateCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-09.
//

import SwiftUI

@MainActor
struct HabitDailyUpdateCell: View {
    let habit: HabitModel

    @StateObject private var viewModel: HabitDailyUpdateCellViewModel

    init(habit: HabitModel) {
        self.habit = habit
        self._viewModel = StateObject(wrappedValue: HabitDailyUpdateCellViewModel(habitModel: habit))
    }

    var body: some View {
        HStack {
            CompletionCheckmarkView(hasCompleted: viewModel.hasCompletedTodayGoal)

            Image(systemName: habit.systemImage)
                .font(.title)
                .foregroundStyle(.tint)
                .frame(width: 30)

            VStack(alignment: .leading) {
                Text(habit.name)
                    .bold()

                ProgressView(value: min(viewModel.dailyValue / habit.value, 1))
                    .foregroundStyle(.tint)

                HStack {
                    Text("\(viewModel.dailyValue.format(using: .oneDecimalPlace)) \(habit.unit.unitString)")
                        .foregroundStyle(.tint)

                    Text("/ \(NumberFormatter.noDecimalPlaces.string(for: habit.value) ?? "") \(habit.unit.unitString)")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
                .bold()
            }
        }
        .tint(habit.color)
        .cardContainer()
        .animation(.easeOut, value: viewModel.dailyValue)
        .standardConfetti(
            $viewModel.didHitGoal,
            colors: [
                habit.measurement.color,
                .white,
                habit.measurement.color.lighter(),
                habit.measurement.color.darker()
            ]
        )
        .onAppear {
            viewModel.checkHitGoal()
        }
    }
}

#Preview {
    ScrollView {
        VStack {
            HabitDailyUpdateCell(habit: .init(measurement: .stepCount, value: 10000))
        }
        .padding()
    }
    .gradientRootBackground()
}
