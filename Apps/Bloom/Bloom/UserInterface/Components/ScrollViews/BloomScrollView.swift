//
//  BloomScrollView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-23.
//

import SwiftUI

struct BloomScrollView<Content>: View where Content: View {

  let showsChatBar: Bool
  let spacing: CGFloat?
  let padding: Edge.Set
  let contentBuilder: () -> Content

  init(
    showsChatBar: Bool = true,
    spacing: CGFloat? = nil,
    padding: Edge.Set = .all,
    @ViewBuilder contentBuilder: @escaping () -> Content
  ) {
    self.showsChatBar = showsChatBar
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
