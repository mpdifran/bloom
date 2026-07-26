//
//  BloomTabView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-18.
//

import SwiftUI
import BloomUI

struct BloomTabView: View {

  @Environment(TabController.self) private var tabController: TabController

  @State private var tabBarHeight: CGFloat = 0

  var body: some View {
    ZStack {
      VStack {
        switch tabController.activeTab {
        case .today:
          TodayView()
        case .nutrition:
          NutritionView()
        case .you:
          YouView()
        case .workouts:
          WorkoutsTabView()
        case .actions:
          ActionsTabView()
        }
      }
      .overlay {
        BloomTabBar()
          .readViewSize { proxy in
            self.tabBarHeight = proxy.size.height
          }
          .zStackAlignment(.bottom)
      }
    }
  }
}

#Preview {
  @Previewable @Bindable var tabController = TabController()

  PreviewEnvironment {
    BloomTabView()
      .environment(tabController)
  }
}
