//
//  UnitTextField.swift
//  Gardener
//
//  Created by Mark DiFranco on 2024-12-14.
//

import SwiftUI

struct UnitTextField: View {
  let type: NutrientType
  @Binding var value: Double?
  @Binding var unit: NutritionUnit

  init(_ type: NutrientType, value: Binding<Double?>, unit: Binding<NutritionUnit>) {
    self.type = type
    self._value = value
    self._unit = unit
  }

  var body: some View {
    HStack {
      TextField(type.displayName, value: $value, format: .number)
      Text(unit.displayName)
        .foregroundStyle(.secondary)
    }
  }
}

#Preview {
  Form {
    UnitTextField(
      .calories,
      value: .constant(300),
      unit: .constant(.calories)
    )
  }
  .formStyle(.grouped)
}

enum NutritionUnit {
  case calories
  case grams
  case milligrams
  case micrograms
  case percentDV

  var displayName: String {
    switch self {
    case .calories: "Cal"
    case .grams: "g"
    case .milligrams: "mg"
    case .micrograms: "µg"
    case .percentDV: "% DV"
    }
  }
}

enum NutrientType {
  case calories
  case carbs
  case fiber
  case sugar
  case fat
  case saturatedFat
  case transFat
  case polyunsaturatedFat
  case monounsaturatedFat
  case protein
  case vitaminA
  case vitaminB6
  case vitaminB12
  case vitaminC
  case vitaminD
  case vitaminE
  case sodium
  case calcium
  case iron
  case potassium
  case magnesium
  case zinc
  case cholesterol

  var displayName: String {
    switch self {
    case .calories: "Calories"
    case .carbs: "Carbohydrates"
    case .fiber: "Fiber"
    case .sugar: "Sugar"
    case .fat: "Fat"
    case .saturatedFat: "Saturated Fat"
    case .transFat: "Trans Fat"
    case .polyunsaturatedFat: "Polyunsaturated Fat"
    case .monounsaturatedFat: "Monounsaturated Fat"
    case .protein: "Protein"
    case .vitaminA: "Vitamin A"
    case .vitaminB6: "Vitamin B6"
    case .vitaminB12: "Vitamin B12"
    case .vitaminC: "Vitamin C"
    case .vitaminD: "Vitamin D"
    case .vitaminE: "Vitamin E"
    case .sodium: "Sodium"
    case .calcium: "Calcium"
    case .iron: "Iron"
    case .potassium: "Potassium"
    case .magnesium: "Magnesium"
    case .zinc: "Zinc"
    case .cholesterol: "Cholesterol"
    }
  }
}
