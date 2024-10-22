//
//  NutritionHabitTodayWidgetView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-16.
//

import SwiftUI
import AppUI
import SwiftData
import DataContainer
import HealthKit

struct NutritionHabitTodayWidgetView: View {

    @State private var viewModel = ViewModel()

    @Query var calorieHabit: [Habit]
    @Query var proteinHabit: [Habit]

    init() {
        let rawCaloriesMetric = TargetMetric.calories.rawValue
        let rawProteinMetric = TargetMetric.proteinIntake.rawValue

        _calorieHabit = Query(
            filter: #Predicate<Habit> { habit in
                habit.endDate == nil &&
                habit.rawTargetMetric == rawCaloriesMetric
            },
            sort: \Habit.startDate,
            order: .reverse
        )
        _proteinHabit = Query(
            filter: #Predicate<Habit> { habit in
                habit.endDate == nil &&
                habit.rawTargetMetric == rawProteinMetric
            },
            sort: \Habit.startDate,
            order: .reverse
        )
    }

    var body: some View {
        VStack(alignment: .leading) {
            if viewModel.hasNoContent {
                VStack {
                    Image(systemName: "fork.knife")
                        .font(.title)
                    Text("No Data")
                        .bold()
                }
                .foregroundStyle(.tertiary)
                .horizontallyCentered()
            } else {
                HStack {
                    Spacer(minLength: 0)
                    calorieCountdownView
                    proteinCountdownView
                }
            }
        }
        .horizontallyCentered()
        .cardContainer(fill: .background.secondary)
    }
}

private extension NutritionHabitTodayWidgetView {

    @ViewBuilder
    var calorieCountdownView: some View {
        if let remainingCalories = viewModel.remainingCalories, let percent = viewModel.remainingCaloriesPercent {
            NavigationLink {
                if let habit = calorieHabit.first {
                    HabitDetailsView(habit: habit)
                }
            } label: {
                NutritionRemainingValueView(
                    systemImage: TargetMetric.calories.systemImage,
                    value: percent,
                    valueText: remainingCalories.displayString(for: .largeCalorie()),
                    title: "Dietary Calories"
                )
                .tint(TargetMetric.calories.color)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    var proteinCountdownView: some View {
        if let remainingProtein = viewModel.remainingProtein, let percent = viewModel.remainingProteinPercent {
            NavigationLink {
                if let habit = proteinHabit.first {
                    HabitDetailsView(habit: habit)
                }
            } label: {
                NutritionRemainingValueView(
                    systemImage: TargetMetric.proteinIntake.systemImage,
                    value: percent,
                    valueText: remainingProtein.displayString(for: .gram()),
                    title: "Protein"
                )
                .tint(TargetMetric.proteinIntake.color)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)
        }
    }
}

#Preview {
    ScrollView {
        VStack {
            NutritionHabitTodayWidgetView()
        }
        .padding()
    }
}
