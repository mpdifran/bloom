//
//  View+Background.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-04.
//

import SwiftUI

extension View {

  func tintedBackground<S: ShapeStyle>(tint: S) -> some View {
    background {
      Rectangle()
        .fill(tint)
        .ignoresSafeArea()
    }
  }

  func gradientRootBackground() -> some View {
    background {
      Rectangle()
        .fill(.background.secondary)
        .ignoresSafeArea()
        .overlay {
          VStack {
            LinearGradient(
              colors: [
                .mutedIndigo.opacity(0.3),
                .mutedBlue.opacity(0.3),
                .mutedGreen.opacity(0.3)
              ],
              startPoint: .leading,
              endPoint: .topTrailing
            )
            .frame(height: 500)
            .mask {
              LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .bottom)
            }
            
            Spacer()
          }
          .ignoresSafeArea()
        }
    }
  }
}

#Preview("Gradient Root Background") {
  NavigationStack {
    ScrollView {
      VStack {
        Text("Hello World")
          .horizontallyCentered()
          .cardContainer()
      }
      .horizontallyCentered()
      .padding()
    }
    .gradientRootBackground()
    .navigationTitle("Today")
  }
}
