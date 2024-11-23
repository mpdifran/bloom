//
//  FoodItemNutritionLabel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-21.
//

import SwiftUI
import BloomModel

struct FoodItemNutritionLabel: View {
    let foodItem: FoodItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Nutrition Label")
                .font(.title2)
                .fontDesign(.rounded)
                .bold()
                .horizontallyCentered()
                .padding(.vertical)

            NutritionLine(name: "Calories", quantity: foodItem.calories, indentationLevel: 0)

            Divider()

            NutritionLine(name: "Fat", quantity: foodItem.fat, indentationLevel: 0)

            Group {
                NutritionLine(name: "Saturated Fat", quantity: nil, indentationLevel: 1)
                NutritionLine(name: "Trans Fat", quantity: nil, indentationLevel: 1)
                NutritionLine(name: "Polyunsaturated Fat", quantity: nil, indentationLevel: 1)
                NutritionLine(name: "Monounsaturated Fat", quantity: nil, indentationLevel: 1)
            }
            .foregroundStyle(.secondary)

            Divider()

            NutritionLine(name: "Cholesterol", quantity: nil, indentationLevel: 0)
            NutritionLine(name: "Sodium", quantity: nil, indentationLevel: 0)

            Divider()

            NutritionLine(name: "Carbohydrates", quantity: foodItem.carbohydrates, indentationLevel: 0)

            Group {
                NutritionLine(name: "Fiber", quantity: nil, indentationLevel: 1)
                NutritionLine(name: "Sugar", quantity: nil, indentationLevel: 1)
            }
            .foregroundStyle(.secondary)

            Divider()

            NutritionLine(name: "Protein", quantity: foodItem.protein, indentationLevel: 0)

            Divider()

            NutritionLine(name: "Calcium", quantity: nil, indentationLevel: 0)
            NutritionLine(name: "Iron", quantity: nil, indentationLevel: 0)
            NutritionLine(name: "Potassium", quantity: nil, indentationLevel: 0)

            Divider()

            NutritionLine(name: "Vitamin A", quantity: nil, indentationLevel: 0)
            NutritionLine(name: "Vitamin C", quantity: nil, indentationLevel: 0)
            NutritionLine(name: "Vitamin D", quantity: nil, indentationLevel: 0)
        }
    }
}

private extension FoodItemNutritionLabel {
    struct NutritionLine: View {
        let name: String
        let quantity: FoodItem.Quantity?
        let indentationLevel: Int

        var body: some View {
            HStack {
                Text(name)
                Spacer()
                if let quantity {
                    Text(quantity.value.format())
                        .font(.body)
                    Text(quantity.unit)
                        .font(.body)
                        .foregroundStyle(.secondary)
                } else {
                    Text("--")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.leading, CGFloat(indentationLevel * 10))
            .font(.headline)
            .fontDesign(.rounded)
            .bold()
        }
    }
}

#Preview {
    FoodItemNutritionLabel(
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
            isVerified: true
        )
    )
}
