//
//  ChatLayout.swift
//  Bloom
//
//  Created by Zach Radford on 2025-05-07.
//

import SwiftUI

struct ChatLayout<Content: View>: View {
  
  @ViewBuilder var content: () -> Content
  
  init(@ViewBuilder content: @escaping () -> Content) {
    self.content = content
  }
  
  var body: some View {
    ScrollView {
      LazyVStack(spacing: 6) {
        content()
      }
    }
    .defaultScrollAnchor(.bottom)
  }
}
