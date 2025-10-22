//
//  View+Shimmer.swift
//  Bloom
//
//  Created by Claude on 2025-10-22.
//

import SwiftUI

struct ShimmerModifier: ViewModifier {
  let duration: Double

  @State private var phase: CGFloat = 0

  func body(content: Content) -> some View {
    content
      .overlay {
        GeometryReader { geometry in
          Rectangle()
            .fill(
              LinearGradient(
                colors: [
                  .clear,
                  .white,
                  .clear
                ],
                startPoint: .leading,
                endPoint: .trailing
              )
            )
            .offset(x: -geometry.size.width + (phase * geometry.size.width * 2))
            .mask(content)
        }
      }
      .onAppear {
        withAnimation(
          .linear(duration: duration)
          .repeatForever(autoreverses: false)
        ) {
          phase = 1
        }
      }
  }
}

extension View {
  /// Adds a continuous shimmer effect that sweeps from left to right
  /// - Parameter duration: Duration of one complete shimmer cycle in seconds (default: 2.0)
  func shimmer(duration: Double = 2.0) -> some View {
    modifier(ShimmerModifier(duration: duration))
  }
}
