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

    var body: some View {
        VStack(alignment: .leading) {
            Text("Remaining Today")
                .font(.subheadline)
                .bold()
                .fontDesign(.rounded)

            Divider()

            HStack {
                Spacer(minLength: 0)
                calorieCountdownView
                proteinCountdownView
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
            NutritionRemainingValueView(
                systemImage: TargetMetric.calories.systemImage,
                value: percent,
                valueText: remainingCalories.displayString(for: .largeCalorie()),
                title: "Dietary Calories"
            )
            .tint(TargetMetric.calories.color)
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    var proteinCountdownView: some View {
        if let remainingProtein = viewModel.remainingProtein, let percent = viewModel.remainingProteinPercent {
            NutritionRemainingValueView(
                systemImage: TargetMetric.proteinIntake.systemImage,
                value: percent,
                valueText: remainingProtein.displayString(for: .gram()),
                title: "Protein"
            )
            .tint(TargetMetric.proteinIntake.color)
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
    .groupedBackground()
}
