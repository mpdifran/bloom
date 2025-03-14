//
//  CurrentThemeView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-14.
//

import SwiftUI

struct CurrentThemeView: View {
  @Environment(ThemeController.self) private var themeController

  var body: some View {
    HStack {
      DisplayAppIcon()
        .frame(square: 24)

      Text(themeController.theme.name)
        .font(.headline)
        .bold()
        .fontDesign(.rounded)
        .contentTransition(.interpolate)
    }
    .padding(.vertical, 8)
    .padding(.horizontal, 12)
    .background {
      Capsule()
        .fill(.background)
    }
    .animation(.easeInOut, value: themeController.theme)
  }
}

#Preview {
  PreviewEnvironment {
    VStack {
      Spacer()
      CurrentThemeView()
      Spacer()
    }
    .horizontallyCentered()
    .groupedBackground()
  }
}
