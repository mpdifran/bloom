//
//  ThemeSelectionCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-13.
//

import SwiftUI

struct ThemeSelectionCell: View {
  let theme: ThemeController.Theme
  let isSelected: Bool

  var body: some View {
    HStack {
      Text(theme.name)
        .font(.headline)
        .foregroundStyle(isSelected ? AnyShapeStyle(.white) : AnyShapeStyle(theme.color))
        .bold()
        .fontDesign(.rounded)

      Spacer()

      DisplayAppIcon(overrideAppIcon: theme.appIcon)
        .frame(square: 40)
    }
    .cardContainer(
      fill: isSelected ? AnyShapeStyle(theme.color) : AnyShapeStyle(.background)
    )
  }
}

#Preview {
  PreviewEnvironment {
    VStack {
      ThemeSelectionCell(theme: .lilac, isSelected: true)
      ThemeSelectionCell(theme: .ultramarine, isSelected: false)
      ThemeSelectionCell(theme: .sunflower, isSelected: false)
    }
  }
}
