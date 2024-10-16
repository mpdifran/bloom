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

            Divider()

            HStack {
                Spacer(minLength: 0)
                calorieCountdownView
                proteinCountdownView
            }
            .padding(.vertical)
        }
        .horizontallyCentered()
        .cardContainer()
    }
}

private extension NutritionHabitTodayWidgetView {

    @ViewBuilder
    var calorieCountdownView: some View {
        if let remainingCalories = viewModel.remainingCalories {
            NutritionRemainingValueView(
                value: remainingCalories.displayString(for: .largeCalorie()),
                subtitle: "Dietary Calories"
            )
            .tint(TargetMetric.calories.color)
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    var proteinCountdownView: some View {
        if let remainingProtein = viewModel.remainingProtein {
            NutritionRemainingValueView(
                value: remainingProtein.displayString(for: .gram()),
                subtitle: "Protein"
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
