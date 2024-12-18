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
    Binding(
      get: {
        NutritionUnitConverter.convert(
          value,
          from: defaultUnit,
          to: unit,
          type: type
        )
      }, set: { newValue in
        value = NutritionUnitConverter.convert(
          newValue,
          from: unit,
          to: defaultUnit,
          type: type
        )
      }
    )
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
