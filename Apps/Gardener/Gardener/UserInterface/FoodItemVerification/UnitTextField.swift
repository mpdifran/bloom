//
//  UnitTextField.swift
//  Gardener
//
//  Created by Mark DiFranco on 2024-12-14.
//

import SwiftUI

struct UnitTextField: View {
  let title: String
  @Binding var value: Double?
  @Binding var unit: NutritionUnit

  init(_ title: String, value: Binding<Double?>, unit: Binding<NutritionUnit>) {
    self.title = title
    self._value = value
    self._unit = unit
  }

  var body: some View {
    HStack {
      TextField(title, value: $value, format: .number)
      Text(unit.displayName)
        .foregroundStyle(.secondary)
    }
  }
}

#Preview {
  Form {
    UnitTextField(
      "Calories",
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
