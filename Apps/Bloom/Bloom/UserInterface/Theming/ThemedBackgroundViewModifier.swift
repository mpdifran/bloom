//
//  ThemedBackgroundViewModifier.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-07.
//

import SwiftUI

struct ThemedBackgroundViewModifier: ViewModifier {

  @Environment(ThemeController.self) private var themeController

  func body(content: Content) -> some View {
    content
      .background {
        Rectangle()
          .fill(.background.secondary)
          .ignoresSafeArea()
      }
  }
}

extension View {

  func groupedBackground() -> some View {
    self.modifier(ThemedBackgroundViewModifier())
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      ScrollView {
        VStack {
          Text("Hello World")
            .bold()
            .fontDesign(.rounded)
            .horizontallyCentered()
            .cardContainer()
        }
        .horizontallyCentered()
        .padding()
      }
      .groupedBackground()
      .navigationTitle("Today")
    }
  }
}
