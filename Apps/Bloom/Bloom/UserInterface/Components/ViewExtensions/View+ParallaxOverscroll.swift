//
//  View+ParallaxOverscroll.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-09-02.
//

import SwiftUI

extension View {

  /// Assumes the view's origin is at the global origin. As the view is moved away from the global origin, it is scaled to ensure the top edge of the view stays at the global origin.
  func parallaxOverscroll() -> some View {
    visualEffect { content, proxy in
      content
        .scaleEffect(max((proxy.frame(in: .global).origin.y + proxy.size.height) / proxy.size.height, 1), anchor: .bottom)
    }
  }
}
