//
//  CardContainer.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-31.
//

import SFSafeSymbols
import SwiftUI
import AppUI
import BloomFoundation

extension View {

  func cardContainer<S, S2>(
    fill: S = BackgroundStyle.background,
    stroke: S2 = .clear,
    lineWidth: CGFloat = 2,
    includePadding: Bool = true,
    cornerRadius: CGFloat = 26
  ) -> some View where S: ShapeStyle, S2: ShapeStyle {
    self
      .if(includePadding) {
        $0.padding()
      }
      .background {
        RoundedRectangle(cornerRadius: cornerRadius)
          .fill(fill)
          .overlay {
            RoundedRectangle(cornerRadius: cornerRadius)
              .stroke(stroke, lineWidth: lineWidth)
          }
      }
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
      .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
  }
}

#Preview {
  ScrollView {
    VStack {
      HStack {
        Spacer()
        Text("Hello\nWorld")
        Spacer()
      }
      .cardContainer()

      HStack {
        Label("Good Morning", systemSymbol: .sunriseFill)
          .foregroundStyle(.mutedGreen)

        Spacer()
      }
      .cardContainer(fill: .mutedGreen.opacity(0.3), stroke: .mutedGreen)
    }
    .padding()
  }
  .groupedBackground()
}
