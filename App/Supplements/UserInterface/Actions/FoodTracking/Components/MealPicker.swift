//
//  MealPicker.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-25.
//

import SwiftUI
import DataContainer

struct MealPicker: View {
    private let nutritionViewModel = NutritionTrackingViewModel.shared

    var body: some View {
        Menu {
            ForEach(FoodItemLog.Meal.allCases, id: \.self) { meal in
                Button(meal.name) {
                    nutritionViewModel.suggestedMeal = meal
                }
            }
        } label: {
            HStack(spacing: 2) {
                Text(nutritionViewModel.suggestedMeal.name)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
            }
            .bold()
            .padding(.vertical)
        }
    }
}

#Preview {
    MealPicker()
}
