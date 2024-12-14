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
  let unit: String

  init(_ title: String, value: Binding<Double?>, unit: String) {
    self.title = title
    self._value = value
    self.unit = unit
  }

  var body: some View {
    HStack {
      TextField(title, value: $value, format: .number)
      Text(unit)
        .foregroundStyle(.secondary)
    }
  }
}

#Preview {
  Form {
    UnitTextField("Calories", value: .constant(300), unit: "Cal")
  }
  .formStyle(.grouped)
}
