//
//  BloomScrollView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-23.
//

import SwiftUI

struct BloomScrollView<Content>: View where Content: View {

  let spacing: CGFloat?
  let padding: Edge.Set
  let contentBuilder: () -> Content

  init(
    spacing: CGFloat? = nil,
    padding: Edge.Set = .all,
    @ViewBuilder contentBuilder: @escaping () -> Content
  ) {
    self.spacing = spacing
    self.padding = padding
    self.contentBuilder = contentBuilder
  }

  var body: some View {
    ScrollView(.vertical) {
      VStack(spacing: spacing) {
        contentBuilder()
      }
      .horizontallyCentered()
      .padding(padding)
    }
    .groupedBackground()
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      Text("Hello World")
        .cardContainer()
    }
  }
}
