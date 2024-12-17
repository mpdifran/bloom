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
        Group {
          switch tabController.activeTab {
          case .today:
            TodayView()
          case .vitals:
            VitalsView()
          case .actions:
            ActionsView()
          case .nutrition:
            NutritionView()
          case .profile:
            PreferencesView()
          }
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
