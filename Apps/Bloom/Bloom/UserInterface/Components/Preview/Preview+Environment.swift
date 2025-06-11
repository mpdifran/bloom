//
//  Preview+Environment.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-13.
//

import SwiftUI
import DataContainer

struct PreviewEnvironment<Content>: View where Content: View {
  let content: () -> Content

  init(@ViewBuilder content: @escaping () -> Content) {
    self.content = content
    ContainerHolder.shared.setupForTests()
  }

  @Bindable private var tabController = TabController()
  @Bindable private var themeController = ThemeController.shared

  var body: some View {
    content()
      .tint(themeController.theme.color)
      .environment(tabController)
      .environment(themeController)
  }
}
