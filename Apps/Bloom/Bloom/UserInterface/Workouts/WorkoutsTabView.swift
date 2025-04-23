//
//  WorkoutsTabView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-30.
//

import SwiftUI

struct WorkoutsTabView: View {

  @Environment(TabController.self) private var tabController: TabController

  var body: some View {
    NavigationStack {
      WorkoutsListView(titleDisplayMode: .large)
        .safeAreaPadding(.bottom, tabController.chatLauncherSafeAreaInset)
    }
  }
}

#Preview {
  WorkoutsTabView()
}
