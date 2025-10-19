//
//  CardContainer.swift
//  BloomUI
//
//  Created by Mark DiFranco on 2024-07-31.
//

import SFSafeSymbols
import SwiftUI
import AppUI
import BloomFoundation

public extension View {

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
      }
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
      .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
      .overlay {
        RoundedRectangle(cornerRadius: cornerRadius)
          .stroke(stroke, lineWidth: lineWidth)
      }
  }
}

public extension View {

  func chatCardContainer<S, S2>(
    fill: S = BackgroundStyle.background.secondary,
    stroke: S2 = .fill,
    lineWidth: CGFloat = 1,
    includePadding: Bool = true,
    cornerRadius: CGFloat = 26
  ) -> some View where S: ShapeStyle, S2: ShapeStyle {
    self
      .cardContainer(
        fill: fill,
        stroke: stroke,
        lineWidth: lineWidth,
        includePadding: includePadding,
        cornerRadius: cornerRadius
      )
  }
}
