//
//  ThemeSelectionCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-13.
//

import SwiftUI
import SFSafeSymbols

struct ThemeSelectionCell: View {
  let theme: ThemeController.Theme
  let isSelected: Bool

  var body: some View {
    HStack {
      DisplayAppIcon(overrideAppIcon: theme.appIcon)
        .frame(square: 40)

      Text(theme.name)
        .font(.headline)
        .foregroundStyle(theme.color)
        .bold()
        .fontDesign(.rounded)

      Spacer()

      if isSelected {
        Image(systemSymbol: .checkmark)
          .bold()
          .fontDesign(.rounded)
          .font(.body)
          .foregroundStyle(theme.color)
      }
    }
    .cardContainer()
  }
}

#Preview {
  PreviewEnvironment {
    VStack {
      ThemeSelectionCell(theme: .purple, isSelected: true)
      ThemeSelectionCell(theme: .blue, isSelected: false)
      ThemeSelectionCell(theme: .orange, isSelected: false)
    }
    .padding()
    .horizontallyCentered()
    .groupedBackground()
  }
}
