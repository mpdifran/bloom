//
//  AIScanFoodItemCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-24.
//

import SwiftUI
import BloomModel

/// This is inspired by `FoodItemCell`.
struct AIScanFoodItemCell: View {
    @Binding var foodItemServing: FoodItemServing

    var body: some View {
        HStack {
            foodDetailsContentView

            Spacer()

            caloriesView
            editContentView
        }
        .cardContainer(fill: .background, stroke: .background.secondary)
    }
}

private extension AIScanFoodItemCell {

    var food: FoodItem {
        foodItemServing.foodItem
    }

    var foodDetailsContentView: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 4) {
                if food.isVerified {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(.white, .mutedGreen)
                    Text("Verified")
                        .foregroundStyle(.mutedGreen)
                        .bold()
                }

                Text(food.brandName ?? "Unknown")
                    .foregroundStyle(.secondary)
                    .bold()
            }
            .font(.caption)

            HStack(alignment: .firstTextBaseline) {
                Text(food.name)
                if let flavour = food.flavour {
                    Text(flavour)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            .bold()

            if
                let serving = food.servingName,
                let servingQuantity = food.servingQuantity
            {
                Text("\(serving) (\(servingQuantity.value.format()) \(servingQuantity.unit))")
                    .font(.caption)
            }
        }
    }

    @ViewBuilder
    var caloriesView: some View {
        if let calories = food.calories?.value {
            VStack(spacing: 0) {
                Text("\(calories.format())")
                    .bold()
                    .font(.title2)
                    .foregroundStyle(.tint)
                Text("cals")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .fontDesign(.rounded)
        }
    }

    var editContentView: some View {
        HStack {
            VStack {
                TextField("", value: $foodItemServing.serving, formatter: NumberFormatter.oneDecimalPlace)
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.center)
                    .frame(width: 70)
                    .fontDesign(.rounded)
                    .keyboardType(.decimalPad)
                    .selectAllTextOnBeginEditing()

                Text("servings")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    AIScanFoodItemCell(
        foodItemServing: .constant(
            .init(
                serving: 2,
                foodItem: .init(
                    id: .init("1234"),
                    name: "Crackers",
                    brandName: "Ritz",
                    flavour: "Low Sodium",
                    calories: .init(value: 100, unit: "kcal"),
                    protein: .init(value: 1, unit: "g"),
                    carbohydrates: .init(value: 13, unit: "g"),
                    fat: .init(value: 4.5, unit: "g"),
                    servingName: "6 crackers",
                    servingQuantity: .init(value: 20, unit: "g"),
                    ingredients: nil,
                    category: .branded,
                    isVerified: true
                )
            )
        )
    )
    .padding()
}
