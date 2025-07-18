//
//  CardView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-01-23.
//

import SwiftUI

struct CardView<Content>: View where Content: View {

  let contentBuilder: () -> Content

  @Environment(ThemeController.self) private var themeController

  init(
    @ViewBuilder contentBuilder: @escaping () -> Content
  ) {
    self.contentBuilder = contentBuilder
  }

  var body: some View {
    VStack {
      contentBuilder()
    }
    .horizontallyCentered()
    .presentationDetentSelfSizing()
    .presentationCornerRadius(30)
    .presentationDragIndicator(.visible)
//    .presentationBackground(themeController.theme.backgroundColor)
  }
}

#Preview {
  PreviewEnvironment {
    PreviewSheetPresent {
      CardView {
        VStack {
          Text("Hello")
          Text("World")
        }
        .padding()
      }
    }
  }
}
