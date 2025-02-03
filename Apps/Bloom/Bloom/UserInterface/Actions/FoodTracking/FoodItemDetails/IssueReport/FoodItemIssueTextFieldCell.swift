//
//  FoodItemIssueTextFieldCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-03.
//

import SwiftUI

struct FoodItemIssueTextFieldCell: View {
  let title: String
  @Binding var text: String

  var body: some View {
    FoodItemEditableCell(
      title: title,
      mode: .value,
      isVertical: true
    ) { resetMode in
        switch resetMode {
        case .clearValue:
          text = ""
        case .resetValue:
          text = ""
        }
      } contentBuilder: {
        TextEditor(text: $text)
          .bold()
          .fontDesign(.rounded)
          .overlay {
            RoundedRectangle(cornerRadius: 13)
              .stroke(.secondary, lineWidth: 0.5)
          }
      }
      .frame(height: 160)
  }
}

#Preview {
  @Previewable @State var text: String = "Apples"

  VStack {
    Spacer()

    FoodItemIssueTextFieldCell(
      title: "Notes",
      text: $text
    )
    .cardContainer()
    .padding()

    Spacer()
  }
  .groupedBackground()
}
