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

  @State private var selectionToggle = false
  @State private var shouldShowLogPeriodSheet = false

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
    .sheet(isPresented: $shouldShowLogPeriodSheet) {
      CycleTrackingActionCardView {
        shouldShowLogPeriodSheet = false
      }
    }
    .animation(.easeInOut(duration: 1), value: userController.isAuthenticated)
    .animation(.easeInOut(duration: 1), value: hasShownOnboarding)
    .onChange(of: tabController.toggleToDismiss) { oldValue, newValue in
      dismiss()
    }
    .onReceive(NotificationCenter.default.publisher(for: .showLogPeriodSheet)) { _ in
      shouldShowLogPeriodSheet = true
    }
    .onOpenURL { url in
      handleURL(url)
    }
    .tint(themeController.theme.color)
    .environment(themeController)
    .environment(experimentManager)
  }
}

private extension RootView {

  func handleURL(_ url: URL) {
    // Support both custom URL scheme (bloom://) and universal links (https://api.trybloom.app)
    guard url.scheme == "bloom" || url.host == "api.trybloom.app" || url.host == "trybloom.app" else { return }

    // For bloom:// URLs, reconstruct the full path from host and path
    // bloom://action/food-scanner -> host="action", path="/food-scanner" -> "/action/food-scanner"
    let path = url.scheme == "bloom" ? "/\(url.host ?? "")\(url.path)" : url.path

    switch path {
    case "/today":
      tabController.activeTab = .today
    case "/paywall":
      tabController.showPaywall = true
    case "/action/food-scanner":
      presentedSheet = AIFoodScannerView().asAny
    case "/action/log-food":
      presentedSheet = FoodLoggingActionCardView(performDismiss: nil).asAny
    case "/action/log-water":
      presentedSheet = WaterActionCardView(performDismiss: nil).asAny
    case "/action/log-bowel-movement":
      presentedSheet = BowelMovementActionCardView(performDismiss: nil).asAny
    case "/action/log-period":
      presentedSheet = CycleTrackingActionCardView(performDismiss: nil).asAny
    case "/action/log-weight":
      presentedSheet = BodyWeightActionCardView(performDismiss: nil).asAny
    case "/action/log-blood-pressure":
      presentedSheet = BloodPressureActionCardView(performDismiss: nil).asAny
    default:
      break
    }
  }

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
    .tabViewBottomAccessory { tabViewAccessoryView }
    .sensoryFeedback(.selection, trigger: selectionToggle)
    .fullScreenCover(isPresented: Binding(
      get: { tabController.isShowingChat },
      set: { tabController.isShowingChat = $0 }
    )) {
      ChatViewControllerRepresentable(
        tabController: tabController,
        themeController: themeController
      )
      .ignoresSafeArea()
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

  var tabViewAccessoryView: some View {
    ChatLauncherTabAccessoryView(presentedSheet: $presentedSheet)
      .onTapGesture {
        EntitledAction(
          presentedSheet: $presentedSheet
        ) {
          tabController.isShowingChat = true
          selectionToggle.toggle()
        }
      }
  }
}

#Preview {
  PreviewEnvironment {
    RootView()
  }
}
