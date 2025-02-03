//
//  FoodItemNameTextCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-03.
//

import SwiftUI

struct FoodItemNameTextCell: View {
  let title: String
  let originalName: String
  @Binding var name: String

  var body: some View {
    FoodItemEditableCell(
      title: title,
      mode: mode) { resetMode in
        switch resetMode {
        case .clearValue:
          name = ""
        case .resetValue:
          name = originalName
        }
      } contentBuilder: {
        TextField("", text: $name)
          .multilineTextAlignment(.trailing)
          .bold()
          .fontDesign(.rounded)
          .if(mode == .modifiedValue) {
            $0.foregroundStyle(.mutedOrange)
          }
          .selectAllTextOnBeginEditing()
          .frame(minHeight: 44)
      }
  }
}

private extension FoodItemNameTextCell {

  var mode: FoodItemEditableCellMode {
    if name != originalName {
      return .modifiedValue
    }
    return .value
  }
}

#Preview {
  @Previewable @State var name: String = "Apples"

  VStack {
    FoodItemNameTextCell(
      title: "Name",
      originalName: "Apples",
      name: $name
    )
    .cardContainer()
    .padding()
  }
  .groupedBackground()
}
