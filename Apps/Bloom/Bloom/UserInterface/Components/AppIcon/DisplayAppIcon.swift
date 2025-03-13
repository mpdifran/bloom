//
//  DisplayAppIcon.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-10.
//

import SwiftUI

struct DisplayAppIcon: View {
  let overrideAppIcon: ImageResource?

  init(overrideAppIcon: ImageResource? = nil) {
    self.overrideAppIcon = overrideAppIcon
  }

  @Environment(ThemeController.self) private var themeController

  var body: some View {
    Image(overrideAppIcon ?? themeController.theme.appIcon)
      .resizable()
      .aspectRatio(contentMode: .fit)
      .shadow(color: .gray, radius: 0.5)
  }
}

#Preview {
  DisplayAppIcon()
    .padding()
}
