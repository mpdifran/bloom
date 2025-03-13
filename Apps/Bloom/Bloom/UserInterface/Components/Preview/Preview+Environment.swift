//
//  Preview+Environment.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-13.
//

import SwiftUI

struct PreviewEnvironment<Content>: View where Content: View {
  let content: () -> Content

  init(@ViewBuilder content: @escaping () -> Content) {
    self.content = content
  }

  @Bindable private var tabController = TabController()
  @Bindable private var themeController = ThemeController()

  var body: some View {
    content()
      .tint(themeController.theme.color)
      .environment(tabController)
      .environment(themeController)
  }
}
