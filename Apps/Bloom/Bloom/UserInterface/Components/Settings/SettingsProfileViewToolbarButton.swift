//
//  SettingsProfileViewToolbarButton.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-18.
//

import SwiftUI
import CoreHealth

struct SettingsProfileViewToolbarButton: ToolbarContent {
  @State private var presentedSheet: AnyView?

  @ObservedObject private var userController = UserController.shared
  @ObservedObject private var healthManager = HealthManager.shared

  @Namespace private var namespace

  var body: some ToolbarContent {
      ToolbarItem(placement: .primaryAction) {
        Button {
          presentedSheet = SettingsView()
            .navigationTransition(.zoom(sourceID: "settings-view", in: namespace))
            .asAny
        } label: {
//          UserProfilePhotoView(dimension: 36)
          glassProfilePhotoView
        }
        .sheet($presentedSheet)
      }
      .matchedTransitionSource(id: "settings-view", in: namespace)
//      .sharedBackgroundVisibility(.hidden)
  }
}

private extension SettingsProfileViewToolbarButton {

  @ViewBuilder
  var glassProfilePhotoView: some View {
    if let image = userController.profilePhoto {
      Image(uiImage: image)
        .resizable()
        .scaledToFill()
        .frame(square: 32)
        .clipShape(Circle())
    } else if healthManager.name.isNotEmpty {
      Text(healthManager.name.prefix(1))
        .font(.system(size: 30, weight: .heavy))
        .bold()
        .fontDesign(.rounded)
        .minimumScaleFactor(0.05)
        .foregroundStyle(.white)
    } else {
      Image(systemSymbol: .personFill)
        .bold()
        .fontDesign(.rounded)
        .foregroundStyle(.white)
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
