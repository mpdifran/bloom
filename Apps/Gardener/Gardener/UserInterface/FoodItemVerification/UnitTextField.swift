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
  let defaultUnit: NutritionUnit // The unit stored in the DB.

  init(
    _ type: NutrientType,
    value: Binding<Double?>,
    unit: Binding<NutritionUnit>,
    defaultUnit: NutritionUnit
  ) {
    self.type = type
    self._value = value
    self._unit = unit
    self.defaultUnit = defaultUnit
  }

  var body: some View {
    HStack {
      TextField(
        type.displayName,
        value: convertedValue,
        format: .number
      )
      Text(unit.displayName)
        .foregroundStyle(.secondary)
    }
  }

  private var convertedValue: Binding<Double?> {
    Binding {
      NutritionUnitConverter.convert(
        value,
        from: defaultUnit,
        to: unit,
        type: type
      )
    } set: { newValue in
      value = NutritionUnitConverter.convert(
        value,
        from: unit,
        to: defaultUnit,
        type: type
      )
    }
  }
}

#Preview {
  Form {
    UnitTextField(
      .calories,
      value: .constant(300),
      unit: .constant(.calories),
      defaultUnit: .calories
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

  /// In milligrams.
  /// From https://www.canada.ca/en/health-canada/services/technical-documents-labelling-requirements/table-daily-values/nutrition-labelling.html.
  var dailyValueAmount: Double? {
    switch self {
    case .calories: nil // don't support this
    case .carbs: nil // don't support this
    case .fiber: 28000
    case .sugar: 100000
    case .fat: 75000
    case .saturatedFat: 20000
    case .transFat: 20000
    case .polyunsaturatedFat: 20000
    case .monounsaturatedFat: 20000
    case .protein: nil // don't support this
    case .vitaminA: 0.9
    case .vitaminB6: 1.7
    case .vitaminB12: 0.0024
    case .vitaminC: 90
    case .vitaminD: 0.02
    case .vitaminE: 15
    case .sodium: 2300
    case .calcium: 1300
    case .iron: 18
    case .potassium: 3400
    case .magnesium: 420
    case .zinc: 11
    case .cholesterol: 300
    }
  }
}

struct NutritionUnitConverter {
  static func convert(
    _ value: Double?,
    from: NutritionUnit,
    to: NutritionUnit,
    type: NutrientType
  ) -> Double? {
    guard let value = value else { return nil }

    guard from != to else { return value } // already done

    // Conversion logic between units
    switch (from, to) {
    case (.grams, .milligrams):
      return value * 1000
    case (.milligrams, .grams):
      return value / 1000
    case (.milligrams, .micrograms):
      return value * 1000
    case (.micrograms, .milligrams):
      return value / 1000
    case (.grams, .micrograms):
      return value * 1_000_000
    case (.micrograms, .grams):
      return value / 1_000_000
    case (.grams, .percentDV):
      if let dailyValue = type.dailyValueAmount {
        return ((1000 * value) / dailyValue) * 100
      }
      return nil
    case (.milligrams, .percentDV):
      if let dailyValue = type.dailyValueAmount {
        return (value / dailyValue) * 100
      }
      return nil
    case (.micrograms, .percentDV):
      if let dailyValue = type.dailyValueAmount {
        return ((value / 1000) / dailyValue) * 100
      }
      return nil
    case (.percentDV, .grams):
      if let dailyValue = type.dailyValueAmount {
        return ((value / 100) * dailyValue) / 1000
      }
      return nil
    case (.percentDV, .milligrams):
      if let dailyValue = type.dailyValueAmount {
        return (value / 100) * dailyValue
      }
      return nil
    case (.percentDV, .micrograms):
      if let dailyValue = type.dailyValueAmount {
        return ((value / 100) * dailyValue) * 1000
      }
      return nil
    default: return value // unsupported cases
    }
  }
}
