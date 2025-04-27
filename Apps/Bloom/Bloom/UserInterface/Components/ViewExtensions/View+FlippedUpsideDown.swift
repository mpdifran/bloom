//
//  View+FlippedUpsideDown.swift
//  Bloom
//
//  Created by Zach Radford on 2025-04-27.
//

import SwiftUI

struct FlippedUpsideDown: ViewModifier {
  func body(content: Content) -> some View {
    content
      .rotationEffect(.degrees(180))
      .scaleEffect(x: -1, y: 1, anchor: .center)
  }
}

extension View {
  func flippedUpsideDown() -> some View {
    modifier(FlippedUpsideDown())
  }
}
