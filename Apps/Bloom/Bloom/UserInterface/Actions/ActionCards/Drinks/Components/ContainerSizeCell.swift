//
//  ContainerSizeCell.swift
//  Bloom
//
//  Created by Claude on 2026-01-23.
//

import SwiftUI
import BloomUI

struct ContainerSizeCell: View {
  let container: ContainerSizeModel
  let drinkColor: Color

  var body: some View {
    VStack(spacing: 16) {
      // Mini container preview using container's own shape
      ContainerShapeView(
        shapeType: container.shapeType,
        fillColor: drinkColor.opacity(0.3),
        strokeColor: drinkColor.opacity(0.6),
        strokeWidth: 1.5
      )
      .frame(width: 40, height: 50)

      VStack {
        Text(container.name)

        Text(container.displayValue())
          .foregroundStyle(.secondary)
      }
      .font(.caption)
      .bold()
      .lineLimit(1)
    }
    .frame(maxWidth: .infinity)
    .padding()
    .background {
      ZStack {
        RoundedRectangle(cornerRadius: 26)
          .fill(.invertedText)
        RoundedRectangle(cornerRadius: 26)
          .fill(.tint.tertiary)
      }
    }
    .contentShape(RoundedRectangle(cornerRadius: 26))
    .tint(drinkColor)
  }
}

#Preview {
  HStack(spacing: 12) {
    ContainerSizeCell(
      container: ContainerSizeModel.defaults[0],
      drinkColor: .blue
    )

    ContainerSizeCell(
      container: ContainerSizeModel.defaults[2],
      drinkColor: .blue
    )

    ContainerSizeCell(
      container: ContainerSizeModel.defaults[4],
      drinkColor: .orange
    )
  }
  .padding()
}
