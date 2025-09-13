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

  @Environment(TabController.self) private var tabController: TabController

  var body: some View {
    ScrollView(.vertical) {
      VStack(spacing: spacing) {
        contentBuilder()
      }
      .horizontallyCentered()
      .padding(padding)
    }
    .groupedBackground()
    .safeAreaPadding(.bottom, bottomPadding)
  }
}

private extension BloomScrollView {

  var bottomPadding: CGFloat {
    if #available(iOS 26, *) {
      return 0
    }
    return showsChatBar ? tabController.chatLauncherSafeAreaInset : 0
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
