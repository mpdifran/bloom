//
//  SettingsProfileViewToolbarButton.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-18.
//

import SwiftUI

struct SettingsProfileViewToolbarButton: ToolbarContent {
  @State private var presentedSheet: AnyView?

  @Namespace private var namespace

  var body: some ToolbarContent {
    if #available(iOS 26.0, *) {
      ToolbarItem(placement: .primaryAction) {
        Button {
          presentedSheet = SettingsView()
            .navigationTransition(.zoom(sourceID: "settings-view", in: namespace))
            .asAny
        } label: {
          UserProfilePhotoView(dimension: 36)
        }
        .sheet($presentedSheet)
      }
      .matchedTransitionSource(id: "settings-view", in: namespace)
      .sharedBackgroundVisibility(.hidden)
    } else {
      ToolbarItem(placement: .primaryAction) {
        Button {
          presentedSheet = SettingsView().asAny
        } label: {
          UserProfilePhotoView(dimension: 32)
        }
        .sheet($presentedSheet)
      }
    }
  }
}

#Preview {
  NavigationStack {
    VStack {
      Text("Hello World")
    }
    .navigationTitle("Preview")
  }
  .toolbar {
    SettingsProfileViewToolbarButton()
  }
}
