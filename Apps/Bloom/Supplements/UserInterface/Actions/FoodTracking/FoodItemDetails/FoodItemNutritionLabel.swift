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
        NutritionLine(name: "Saturated Fat", quantity: foodItem.saturatedFat, indentationLevel: 1)
        NutritionLine(name: "Trans Fat", quantity: foodItem.transFat, indentationLevel: 1)
        NutritionLine(name: "Polyunsaturated Fat", quantity: foodItem.polyunsaturatedFat, indentationLevel: 1, showIfNil: false)
        NutritionLine(name: "Monounsaturated Fat", quantity: foodItem.monounsaturatedFat, indentationLevel: 1, showIfNil: false)
      }
      .foregroundStyle(.secondary)

      Divider()

      NutritionLine(name: "Cholesterol", quantity: foodItem.cholesterol, indentationLevel: 0)
      NutritionLine(name: "Sodium", quantity: foodItem.sodium, indentationLevel: 0)

      Divider()

      NutritionLine(name: "Carbohydrates", quantity: foodItem.carbohydrates, indentationLevel: 0)

      Group {
        NutritionLine(name: "Fiber", quantity: foodItem.fiber, indentationLevel: 1)
        NutritionLine(name: "Sugar", quantity: foodItem.sugar, indentationLevel: 1)
      }
      .foregroundStyle(.secondary)

      Divider()

      NutritionLine(name: "Protein", quantity: foodItem.protein, indentationLevel: 0)

      if hasAtLeastOneMineral {
        Divider()

        NutritionLine(name: "Calcium", quantity: foodItem.calcium, indentationLevel: 0, showIfNil: false)
        NutritionLine(name: "Iron", quantity: foodItem.iron, indentationLevel: 0, showIfNil: false)
        NutritionLine(name: "Magnesium", quantity: foodItem.magnesium, indentationLevel: 0, showIfNil: false)
        NutritionLine(name: "Potassium", quantity: foodItem.potassium, indentationLevel: 0, showIfNil: false)
        NutritionLine(name: "Zinc", quantity: foodItem.zinc, indentationLevel: 0, showIfNil: false)
      }

      if hasAtLeastOneVitamin {
        Divider()
        
        NutritionLine(name: "Vitamin A", quantity: foodItem.vitaminA, indentationLevel: 0, showIfNil: false)
        NutritionLine(name: "Vitamin B6", quantity: foodItem.vitaminB6, indentationLevel: 0, showIfNil: false)
        NutritionLine(name: "Vitamin B12", quantity: foodItem.vitaminB12, indentationLevel: 0, showIfNil: false)
        NutritionLine(name: "Vitamin C", quantity: foodItem.vitaminC, indentationLevel: 0, showIfNil: false)
        NutritionLine(name: "Vitamin D", quantity: foodItem.vitaminD, indentationLevel: 0, showIfNil: false)
        NutritionLine(name: "Vitamin E", quantity: foodItem.vitaminE, indentationLevel: 0, showIfNil: false)
      }
    }
  }
}

private extension FoodItemNutritionLabel {
  var hasAtLeastOneMineral: Bool {
    foodItem.calcium != nil ||
    foodItem.iron != nil ||
    foodItem.magnesium != nil ||
    foodItem.potassium != nil ||
    foodItem.zinc != nil
  }

  var hasAtLeastOneVitamin: Bool {
    foodItem.vitaminA != nil ||
    foodItem.vitaminB6 != nil ||
    foodItem.vitaminB12 != nil ||
    foodItem.vitaminC != nil ||
    foodItem.vitaminD != nil ||
    foodItem.vitaminE != nil
  }
}

private extension FoodItemNutritionLabel {
  struct NutritionLine: View {
    let name: String
    let quantity: FoodItem.Quantity?
    let indentationLevel: Int
    let showIfNil: Bool

    init(
      name: String,
      quantity: FoodItem.Quantity?,
      indentationLevel: Int,
      showIfNil: Bool = true
    ) {
      self.name = name
      self.quantity = quantity
      self.indentationLevel = indentationLevel
      self.showIfNil = showIfNil
    }

    var body: some View {
      if showIfNil {
        nutritionLine(for: quantity)
      } else if let quantity {
        nutritionLine(for: quantity)
      }
    }

    func nutritionLine(for quantity: FoodItem.Quantity?) -> some View {
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
    foodItem: .Preview.ritzCrackers
  )
  .padding()
}
