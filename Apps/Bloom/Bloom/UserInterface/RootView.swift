//
//  RootView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-09.
//

import SwiftUI
import AppUI

@MainActor
struct RootView: View {

  @AppStorage("hasShownOnboardingV3") var hasShownOnboarding: Bool = false
  @AppStorage(.FeatureFlag.danieleMode) private var danieleMode = false

  @Bindable private var tabController = TabController()

  @State private var entitlementController = EntitlementController.shared
  @State private var presentedSheet: AnyView?

  @Environment(\.dismiss) private var dismiss

  init() {
    let largeTitleFont = UIFont.systemFont(ofSize: 35, weight: .bold)
    let regularTitleFont = UIFont.systemFont(ofSize: 17, weight: .bold)

    UINavigationBar.appearance().largeTitleTextAttributes = [.font: largeTitleFont.rounded]
    UINavigationBar.appearance().titleTextAttributes = [.font: regularTitleFont.rounded]
  }

  var body: some View {
    Group {
      if !hasShownOnboarding {
        ZStack {
          OnboardingRootView {
            withAnimation {
              hasShownOnboarding = true
            }
          }

        #if DEBUG
          Button("[DEBUG] Skip onboarding") {
            withAnimation {
              hasShownOnboarding = true
            }
          }
          .zStackAlignment(.topTrailing)
        #endif
        }
      } else {
        ZStack {
          TodayView()
            .opacity(tabController.activeTab == .today ? 1 : 0)
          NutritionView()
            .opacity(tabController.activeTab == .nutrition ? 1 : 0)
          VitalsView()
            .opacity(tabController.activeTab == .vitals ? 1 : 0)
          WorkoutsTabView()
            .opacity(tabController.activeTab == .workouts ? 1 : 0)
        }
        .environment(tabController)
        .transition(.blurReplace)
      }
    }
    .sheet($presentedSheet)
    .animation(.easeInOut(duration: 1), value: hasShownOnboarding)
    .animation(.default, value: danieleMode)
    .onChange(of: tabController.toggleToDismiss) { oldValue, newValue in
      dismiss()
    }
    .onChange(of: entitlementController.hasBloomPro) { _, _ in
      if entitlementController.hasBloomPro == false, hasShownOnboarding {
        presentedSheet = BloomPlusPaywall(showDismiss: false).asAny
      }
    }
  }
}

#Preview {
  RootView()
}
