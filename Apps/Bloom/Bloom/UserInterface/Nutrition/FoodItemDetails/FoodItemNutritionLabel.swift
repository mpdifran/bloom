//
//  FoodItemNutritionLabel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-21.
//

import SwiftUI
import BloomModel
import HealthKit

struct FoodItemNutritionLabel: View {
  let foodItem: FoodItem
  var numberOfServings: Double = 1

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      VStack(spacing: 4) {
        Text("Nutrition Label")
          .font(.title2)
          .fontDesign(.rounded)
          .bold()

        Text("per \(numberOfServings.formatted(.number.precision(.fractionLength(0...2)))) serving\(numberOfServings == 1 ? "" : "s")")
          .font(.subheadline)
          .fontDesign(.rounded)
          .foregroundStyle(.secondary)
      }
      .horizontallyCentered()
      .padding(.bottom)

      NutritionLine(
        name: "Calories",
        quantity: foodItem.calories,
        preferredUnit: .largeCalorie(),
        indentationLevel: 0,
        numberOfServings: numberOfServings
      )

      Divider()

      NutritionLine(
        name: "Fat",
        quantity: foodItem.fat,
        preferredUnit: .gram(),
        indentationLevel: 0,
        numberOfServings: numberOfServings
      )

      Group {
        NutritionLine(
          name: "Saturated Fat",
          quantity: foodItem.saturatedFat,
          preferredUnit: .gram(),
          indentationLevel: 1,
          numberOfServings: numberOfServings
        )
        NutritionLine(
          name: "Trans Fat",
          quantity: foodItem.transFat,
          preferredUnit: .gram(),
          indentationLevel: 1,
          numberOfServings: numberOfServings
        )
        NutritionLine(
          name: "Polyunsaturated Fat",
          quantity: foodItem.polyunsaturatedFat,
          preferredUnit: .gram(),
          indentationLevel: 1,
          showIfNil: false,
          numberOfServings: numberOfServings
        )
        NutritionLine(
          name: "Monounsaturated Fat",
          quantity: foodItem.monounsaturatedFat,
          preferredUnit: .gram(),
          indentationLevel: 1,
          showIfNil: false,
          numberOfServings: numberOfServings
        )
      }
      .foregroundStyle(.secondary)

      Divider()

      NutritionLine(
        name: "Cholesterol",
        quantity: foodItem.cholesterol,
        preferredUnit: .gramUnit(with: .milli),
        indentationLevel: 0,
        numberOfServings: numberOfServings
      )
      NutritionLine(
        name: "Sodium",
        quantity: foodItem.sodium,
        preferredUnit: .gramUnit(with: .milli),
        indentationLevel: 0,
        numberOfServings: numberOfServings
      )

      Divider()

      NutritionLine(
        name: "Carbohydrates",
        quantity: foodItem.carbohydrates,
        preferredUnit: .gram(),
        indentationLevel: 0,
        numberOfServings: numberOfServings
      )

      Group {
        NutritionLine(
          name: "Fiber",
          quantity: foodItem.fiber,
          preferredUnit: .gram(),
          indentationLevel: 1,
          numberOfServings: numberOfServings
        )
        NutritionLine(
          name: "Sugar",
          quantity: foodItem.sugar,
          preferredUnit: .gram(),
          indentationLevel: 1,
          numberOfServings: numberOfServings
        )
      }
      .foregroundStyle(.secondary)

      Divider()

      NutritionLine(
        name: "Protein",
        quantity: foodItem.protein,
        preferredUnit: .gram(),
        indentationLevel: 0,
        numberOfServings: numberOfServings
      )

      if hasAtLeastOneMineral {
        Divider()

        NutritionLine(
          name: "Calcium",
          quantity: foodItem.calcium,
          preferredUnit: .gramUnit(with: .milli),
          indentationLevel: 0,
          showIfNil: false,
          numberOfServings: numberOfServings
        )
        NutritionLine(
          name: "Iron",
          quantity: foodItem.iron,
          preferredUnit: .gramUnit(with: .milli),
          indentationLevel: 0,
          showIfNil: false,
          numberOfServings: numberOfServings
        )
        NutritionLine(
          name: "Magnesium",
          quantity: foodItem.magnesium,
          preferredUnit: .gramUnit(with: .milli),
          indentationLevel: 0,
          showIfNil: false,
          numberOfServings: numberOfServings
        )
        NutritionLine(
          name: "Potassium",
          quantity: foodItem.potassium,
          preferredUnit: .gramUnit(with: .milli),
          indentationLevel: 0,
          showIfNil: false,
          numberOfServings: numberOfServings
        )
        NutritionLine(
          name: "Zinc",
          quantity: foodItem.zinc,
          preferredUnit: .gramUnit(with: .milli),
          indentationLevel: 0,
          showIfNil: false,
          numberOfServings: numberOfServings
        )
      }

      if hasAtLeastOneVitamin {
        Divider()
        
        NutritionLine(
          name: "Vitamin A",
          quantity: foodItem.vitaminA,
          preferredUnit: .gramUnit(with: .micro),
          indentationLevel: 0,
          showIfNil: false,
          numberOfServings: numberOfServings
        )
        NutritionLine(
          name: "Vitamin B6",
          quantity: foodItem.vitaminB6,
          preferredUnit: .gramUnit(with: .milli),
          indentationLevel: 0,
          showIfNil: false,
          numberOfServings: numberOfServings
        )
        NutritionLine(
          name: "Vitamin B12",
          quantity: foodItem.vitaminB12,
          preferredUnit: .gramUnit(with: .micro),
          indentationLevel: 0,
          showIfNil: false,
          numberOfServings: numberOfServings
        )
        NutritionLine(
          name: "Vitamin C",
          quantity: foodItem.vitaminC,
          preferredUnit: .gramUnit(with: .milli),
          indentationLevel: 0,
          showIfNil: false,
          numberOfServings: numberOfServings
        )
        NutritionLine(
          name: "Vitamin D",
          quantity: foodItem.vitaminD,
          preferredUnit: .gramUnit(with: .micro),
          indentationLevel: 0,
          showIfNil: false,
          numberOfServings: numberOfServings
        )
        NutritionLine(
          name: "Vitamin E",
          quantity: foodItem.vitaminE,
          preferredUnit: .gramUnit(with: .milli),
          indentationLevel: 0,
          showIfNil: false,
          numberOfServings: numberOfServings
        )
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
    let preferredUnit: HKUnit
    let indentationLevel: Int
    let showIfNil: Bool
    let numberOfServings: Double

    init(
      name: String,
      quantity: FoodItem.Quantity?,
      preferredUnit: HKUnit,
      indentationLevel: Int,
      showIfNil: Bool = true,
      numberOfServings: Double = 1
    ) {
      self.name = name
      self.quantity = quantity
      self.preferredUnit = preferredUnit
      self.indentationLevel = indentationLevel
      self.showIfNil = showIfNil
      self.numberOfServings = numberOfServings
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
          let scaled = FoodItem.Quantity(value: quantity.value * numberOfServings, unit: quantity.unit)
          Text(scaled.hkQuantity.displayString(for: preferredUnit, formatter: .threeDecimalPlaces))
            .font(.body)
        } else {
          Text(verbatim: "--")
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
