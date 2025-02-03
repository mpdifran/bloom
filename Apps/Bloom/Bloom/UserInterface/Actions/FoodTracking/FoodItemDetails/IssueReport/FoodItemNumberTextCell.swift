//
//  FoodItemNumberTextCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-03.
//

import SwiftUI

struct FoodItemNumberTextCell: View {
  let title: String
  let originalValue: Double
  @Binding var value: Double

  var body: some View {
    FoodItemEditableCell(
      title: title,
      mode: mode,
      canClearValue: false
    ) { resetMode in
        switch resetMode {
        case .clearValue:
          value = -1
        case .resetValue:
          value = originalValue
        }
      } contentBuilder: {
        TextField("", value: $value, formatter: NumberFormatter.twoDecimalPlaces)
          .textFieldStyle(.roundedBorder)
          .multilineTextAlignment(.trailing)
          .frame(width: 100)
          .bold()
          .fontDesign(.rounded)
          .keyboardType(.decimalPad)
          .if(mode == .modifiedValue) {
            $0.foregroundStyle(.mutedOrange)
          }
          .selectAllTextOnBeginEditing()
      }
  }
}

private extension FoodItemNumberTextCell {

  var mode: FoodItemEditableCellMode {
    if value != originalValue {
      return .modifiedValue
    }
    return .value
  }
}

#Preview {
  @Previewable @State var value: Double = 42

  VStack {
    FoodItemNumberTextCell(
      title: "Name",
      originalValue: 42,
      value: $value
    )
    .cardContainer()
    .padding()
  }
  .groupedBackground()
}
