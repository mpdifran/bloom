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
  let experimentVariant: ExperimentVariant?

  @Bindable private var tabController = TabController()
  @Bindable private var themeController = ThemeController.shared
  @Bindable private var experimentManager: ExperimentManager

  @State private var presentedSheet: AnyView?
  
  init(
    variant: ExperimentVariant? = nil,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.content = content
    self.experimentVariant = variant
    self.experimentManager = ExperimentManager(overrideVariant: experimentVariant)
    ContainerHolder.shared.setupForTests()
  }

  var body: some View {
    content()
      .sheet($presentedSheet)
      .tint(themeController.theme.color)
      .overlay {
        Button {
          presentedSheet = DeveloperSettingsView().asAny
        } label: {
          Label("Developer Menu", systemSymbol: .curlybracesSquareFill)
            .foregroundStyle(.white, .mutedYellow)
            .font(.title2)
            .bold()
        }
        .labelStyle(.iconOnly)
        .padding(20)
        .padding(.horizontal)
        .zStackAlignment(.topTrailing)
        .ignoresSafeArea()
      }
      .environment(tabController)
      .environment(themeController)
      .environment(experimentManager)
  }
}
