//
//  View+FlippedVertically.swift
//  Bloom
//
//  Created by Zach Radford on 2025-04-27.
//

import SwiftUI

/// Combination of rotation and horizontal scaling rather than vertical scaling alone.
/// It's visually the same as .scaleEffect(x: 1, y: -1)
/// This transformation preserves better scroll boundary detection characteristics like onAppear/onDisappear.
struct FlippedVertically: ViewModifier {
  func body(content: Content) -> some View {
    content
      .rotationEffect(.degrees(180))
      .scaleEffect(x: -1, y: 1, anchor: .center)
  }
}

extension View {
  func flippedVertically() -> some View {
    modifier(FlippedVertically())
  }
}
