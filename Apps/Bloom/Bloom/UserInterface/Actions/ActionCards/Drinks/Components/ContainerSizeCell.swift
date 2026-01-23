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
  let shapeType: ContainerShapeType
  let drinkColor: Color

  var body: some View {
    VStack(spacing: 8) {
      // Mini container preview
      ContainerShapeView(
        shapeType: shapeType,
        fillColor: drinkColor.opacity(0.3),
        strokeColor: drinkColor.opacity(0.6),
        strokeWidth: 1.5
      )
      .frame(width: 40, height: 50)

      // Name
      Text(container.name)
        .font(.caption)
        .fontWeight(.medium)
        .lineLimit(1)

      // Volume
      Text(container.displayValue())
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
    .background {
      RoundedRectangle(cornerRadius: 16)
        .fill(.tint.tertiary)
    }
    .contentShape(RoundedRectangle(cornerRadius: 16))
    .tint(drinkColor)
  }
}

#Preview {
  HStack(spacing: 12) {
    ContainerSizeCell(
      container: ContainerSizeModel.defaults[0],
      shapeType: .glass,
      drinkColor: .blue
    )

    ContainerSizeCell(
      container: ContainerSizeModel.defaults[2],
      shapeType: .glass,
      drinkColor: .blue
    )

    ContainerSizeCell(
      container: ContainerSizeModel.defaults[4],
      shapeType: .beerGlass,
      drinkColor: .orange
    )
  }
  .padding()
}
