//
//  RootView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-09.
//

import SwiftUI

@MainActor
struct RootView: View {

  @AppStorage("hasShownOnboardingV3") var hasShownOnboarding: Bool = false
  @AppStorage("PreferencesView.danieleMode") private var danieleMode = false

  @Bindable private var tabController = TabController()

  @Environment(\.dismiss) private var dismiss

  init() {
    let largeTitleFont = UIFont.systemFont(ofSize: 35, weight: .bold)
    let regularTitleFont = UIFont.systemFont(ofSize: 17, weight: .bold)

    UINavigationBar.appearance().largeTitleTextAttributes = [.font : largeTitleFont.rounded]
    UINavigationBar.appearance().titleTextAttributes = [.font : regularTitleFont.rounded]
  }

  var body: some View {
    Group {
      if !hasShownOnboarding {
        OnboardingRootView {
          withAnimation {
            hasShownOnboarding = true
          }
        }
      } else {
        ZStack {
          TodayView()
            .opacity(tabController.activeTab == .today ? 1 : 0)
          VitalsView()
            .opacity(tabController.activeTab == .vitals ? 1 : 0)
          NutritionView()
            .opacity(tabController.activeTab == .nutrition ? 1 : 0)
          PreferencesView()
            .opacity(tabController.activeTab == .profile ? 1 : 0)
        }
        .environment(tabController)
        .transition(.blurReplace)
      }
    }
    .animation(.easeInOut(duration: 1), value: hasShownOnboarding)
    .animation(.default, value: danieleMode)
    .onChange(of: tabController.toggleToDismiss) { oldValue, newValue in
      dismiss()
    }
  }
}

#Preview {
  RootView()
}
