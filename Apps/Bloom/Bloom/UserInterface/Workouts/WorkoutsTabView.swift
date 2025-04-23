//
//  WorkoutsTabView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-30.
//

import SwiftUI

struct WorkoutsTabView: View {

  @Environment(TabController.self) private var tabController: TabController

  @State private var presentedSheet: AnyView?

  var body: some View {
    NavigationStack {
      WorkoutsListView(titleDisplayMode: .large)
        .toolbar {
          ToolbarItem(placement: .primaryAction) {
            Button {
              presentedSheet = SettingsView().asAny
            } label: {
              UserProfilePhotoView(dimension: 32)
            }
          }
        }
        .safeAreaPadding(.bottom, tabController.chatLauncherSafeAreaInset)
    }
    .sheet($presentedSheet)
  }
}

#Preview {
  WorkoutsTabView()
}
