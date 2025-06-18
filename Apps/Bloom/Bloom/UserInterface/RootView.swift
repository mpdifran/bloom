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

  @Bindable private var tabController = TabController()
  @Bindable private var themeController = ThemeController.shared
  @Bindable private var experimentManager = ExperimentManager()

  @ObservedObject private var entitlementController = EntitlementController.shared
  @State private var presentedSheet: AnyView?

  @ObservedObject private var userController = UserController.shared

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
          Button {
            withAnimation {
              hasShownOnboarding = true
            }
          } label: {
            Text("Skip")
              .padding()
          }
          .bold()
          .fontDesign(.rounded)
          .zStackAlignment(.topTrailing)
        #endif
        }
      } else if !userController.isAuthenticated {
        OnboardingLoginView { }
      } else {
        if #available(iOS 26, *) {
          newContentView
        } else {
          legacyContentView
        }
      }
    }
    .sheet($presentedSheet)
    .animation(.easeInOut(duration: 1), value: userController.isAuthenticated)
    .animation(.easeInOut(duration: 1), value: hasShownOnboarding)
    .onChange(of: tabController.toggleToDismiss) { oldValue, newValue in
      dismiss()
    }
    .tint(themeController.theme.color)
    .environment(themeController)
    .environment(experimentManager)
  }
}

private extension RootView {

  @available(iOS 26.0, *)
  var newContentView: some View {
    TabView(selection: $tabController.activeTab) {
      TodayView()
        .tag(Tab.today)
      NutritionView()
        .tag(Tab.nutrition)
      VitalsView()
        .tag(Tab.vitals)
      WorkoutsTabView()
        .tag(Tab.workouts)
    }
    .tabBarMinimizeBehavior(.onScrollDown)
    .tabViewBottomAccessory {
      VStack {
        Spacer(minLength: 0)
        HStack {
          Image(systemSymbol: .sparkles)
          TextField("Chat with Bud", text: .constant(""))

          Button {

          } label: {
            Image(systemSymbol: .arrowUpCircleFill)
              .foregroundStyle(.white, .tint)
          }
        }
        .frame(minHeight: 44)
        Spacer(minLength: 0)
      }
      .padding()
    }
    .environment(tabController)
  }

  var legacyContentView: some View {
    Group {
      switch tabController.activeTab {
      case .today:
        TodayView()
      case .nutrition:
        NutritionView()
      case .vitals:
        VitalsView()
      case .workouts:
        WorkoutsTabView()
      }
    }
    .chatLauncher()
    .environment(tabController)
    .transition(.blurReplace)
  }
}

#Preview {
  RootView()
}
