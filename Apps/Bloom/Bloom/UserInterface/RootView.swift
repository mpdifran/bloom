//
//  RootView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-09.
//

import SwiftUI
import UIKit
import AppUI
import TelemetryDeck
import DataContainer
import SwiftData
import BloomFoundation
import CoreHealth

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
  @State private var alertDetails: AlertDetails?

  @ObservedObject private var userController = UserController.shared

  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext

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
          OnboardingRootViewTreatment {
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
    .alert(alertDetails: $alertDetails)
    .animation(.easeInOut(duration: 1), value: userController.isAuthenticated)
    .animation(.easeInOut(duration: 1), value: hasShownOnboarding)
    .onChange(of: tabController.toggleToDismiss) { oldValue, newValue in
      dismiss()
    }
    .onReceive(NotificationCenter.default.publisher(for: .showLogPeriodSheet)) { _ in
      if HealthManager.shared.sex() == .female {
        shouldShowLogPeriodSheet = true
      } else {
        alertDetails = AlertDetails(
          title: "Not Supported",
          message: "Period tracking is not supported for male users."
        )
      }
    }
    .onForeground {
      Task {
        await checkModalSheetToPresent()
      }
    }
    .onForegroundTask {
      await MagicScanStatusChecker.shared.checkPendingItems(modelContext: modelContext)
      await ConsentManager.shared.syncPendingConsentIfNeeded()
    }
    .onOpenURL { url in
      handleURL(url)
    }
    .onChange(of: tabController.pendingYearInBloomNavigation) { _, year in
      if let year {
        presentedSheet = YearInBloomStoriesView(year: year).asAny
        tabController.pendingYearInBloomNavigation = nil
      }
    }
    .tint(themeController.theme.color)
    .environment(themeController)
    .environment(experimentManager)
    .environment(tabController)
  }
}

private extension RootView {

  func checkModalSheetToPresent() async {
    guard
      hasShownOnboarding,
      userController.isAuthenticated
    else { return }

    let sheetKind = await RootViewModalPresentationManager.shared.determineSheetToPresent()

    if sheetKind != nil {
      // Dismiss any presented views before handling navigation
      dismiss()
      presentedSheet = nil
      shouldShowLogPeriodSheet = false
      tabController.isShowingChat = false
      await Delay(600)
    }

    // Verify app is still in foreground before presenting
    guard UIApplication.shared.applicationState == .active else { return }

    switch sheetKind {
    case .privacyUnknownSheet(let missingConsentTypes):
      presentedSheet = ExistingUserConsentContainerView(missingConsentTypes: missingConsentTypes).asAny
    case .sale(let saleDetails, let preloadedImage):
      presentedSheet = SaleModalView(sale: saleDetails, preloadedImage: preloadedImage).asAny
    case .celebration(let kind):
      presentedSheet = CelebrationModalView(kind: kind).asAny
    case nil:
      break
    }
  }

  func handleURL(_ url: URL) {
    // Support both custom URL scheme (bloom://) and universal links (https://api.trybloom.app)
    guard url.scheme == "bloom" || url.host == "api.trybloom.app" || url.host == "trybloom.app" else { return }

    // For bloom:// URLs, reconstruct the full path from host and path
    // bloom://action/food-scanner -> host="action", path="/food-scanner" -> "/action/food-scanner"
    let path = url.scheme == "bloom" ? "/\(url.host ?? "")\(url.path)" : url.path

    // Track which URLs are being opened
    let urlScheme = url.scheme ?? "unknown"
    var wasHandled = true

    // Dismiss any presented views before handling navigation
    presentedSheet = nil
    shouldShowLogPeriodSheet = false
    tabController.isShowingChat = false

    switch path {
    case "/today":
      tabController.activeTab = .today
    case "/paywall":
      // Parse focus parameter from query string
      let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
      let focusParam = components?.queryItems?.first(where: { $0.name == "focus" })?.value
      let focus: BloomPlusPaywall.Focus

      switch focusParam {
      case "todayInsights":
        focus = .todayInsights
      case "monitor":
        focus = .monitor
      default:
        focus = .standard
      }

      EntitledAction(presentedSheet: $presentedSheet, focus: focus) {
        // Do nothing
      }
    case "/action/magic-scan":
      EntitledAction(presentedSheet: $presentedSheet) {
        presentedSheet = MagicScannerCameraView().asAny
      }
    case "/action/barcode-scan":
      EntitledAction(presentedSheet: $presentedSheet) {
        presentedSheet = BarcodeScannerView().asAny
      }
    case "/action/log-food":
      presentedSheet = FoodLoggingActionCardView(performDismiss: nil).asAny
    case "/action/log-water":
      presentedSheet = WaterActionCardView(performDismiss: nil).asAny
    case "/action/log-bowel-movement":
      presentedSheet = BowelMovementActionCardView(performDismiss: nil).asAny
    case "/action/log-period":
      if HealthManager.shared.sex() == .female {
        presentedSheet = CycleTrackingActionCardView(performDismiss: nil).asAny
      } else {
        alertDetails = AlertDetails(
          title: "Not Supported",
          message: "Period tracking is not supported for male users."
        )
      }
    case "/action/log-weight":
      presentedSheet = BodyWeightActionCardView(performDismiss: nil).asAny
    case "/action/log-blood-pressure":
      presentedSheet = BloodPressureActionCardView(performDismiss: nil).asAny
    case "/action/voice-logger":
      EntitledAction(presentedSheet: $presentedSheet) {
        presentedSheet = VoiceLoggerView(performDismiss: nil).asAny
      }
    case "/vital/sleep-quality":
      tabController.activeTab = .you
      Delay(600) {
        tabController.pendingVitalNavigation = .sleepQuality
      }
    case "/vital/activity-level":
      tabController.activeTab = .you
      Delay(600) {
        tabController.pendingVitalNavigation = .activityLevel
      }
    case "/vital/heart-health":
      tabController.activeTab = .you
      Delay(600) {
        tabController.pendingVitalNavigation = .heartHealth
      }
    case "/vital/body-composition":
      tabController.activeTab = .you
      Delay(600) {
        tabController.pendingVitalNavigation = .bodyComposition
      }
    case "/vital/stress-levels":
      tabController.activeTab = .you
      Delay(600) {
        tabController.pendingVitalNavigation = .stressLevels
      }
    case "/vital/nutrition":
      tabController.activeTab = .you
      Delay(600) {
        tabController.pendingVitalNavigation = .nutrition
      }
    case "/vital/exercise-effectiveness":
      tabController.activeTab = .you
      Delay(600) {
        tabController.pendingVitalNavigation = .exerciseEffectiveness
      }
    case "/vital/cycle-tracking":
      tabController.activeTab = .you
      Delay(600) {
        tabController.pendingVitalNavigation = .cycleTracking
      }
    case "/vital/bowel-movements":
      tabController.activeTab = .you
      Delay(600) {
        tabController.pendingVitalNavigation = .bowelMovements
      }
    case "/vital/cardio-fitness":
      tabController.activeTab = .you
      Delay(600) {
        tabController.pendingVitalNavigation = .cardioFitness
      }
    case "/nutrition":
      tabController.activeTab = .nutrition
    case "/you/steps":
      tabController.activeTab = .you
      Delay(600) {
        tabController.pendingStepsNavigation = true
      }
    case "/launch":
      // Just open the app, no specific action needed
      break
    default:
      // Handle goal deep links: /goals/{goalId}
      if path.hasPrefix("/goals/") {
        let goalId = String(path.dropFirst("/goals/".count))
        tabController.activeTab = .today
        Delay(600) {
          tabController.pendingGoalNavigation = goalId
        }
      } else if path.hasPrefix("/nutrition/food-item-log/") {
        let logId = String(path.dropFirst("/nutrition/food-item-log/".count))
        tabController.activeTab = .nutrition
        Delay(600) {
          tabController.pendingFoodItemLogNavigation = logId
        }
      } else if path.hasPrefix("/nutrition/food-item/") {
        let foodItemId = String(path.dropFirst("/nutrition/food-item/".count))
        tabController.activeTab = .nutrition
        Delay(600) {
          tabController.pendingFoodItemNavigation = foodItemId
        }
      } else if path.hasPrefix("/nutrition/saved-meal/") {
        let mealId = String(path.dropFirst("/nutrition/saved-meal/".count))
        tabController.activeTab = .nutrition
        Delay(600) {
          tabController.pendingSavedMealNavigation = mealId
        }
      } else if path == "/year-in-bloom" {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if let yearString = components?.queryItems?.first(where: { $0.name == "year" })?.value,
           let year = Int(yearString) {
          // Only show if it's at least Dec 15th of that year
          let now = Date()
          let calendar = Calendar.current
          if let dec15 = calendar.date(from: DateComponents(year: year, month: 12, day: 15)),
             now >= dec15 {
            Delay(600) {
              tabController.pendingYearInBloomNavigation = year
            }
          }
        }
      } else {
        wasHandled = false
      }
    }

    // Send analytics after handling the URL
    TelemetryDeck.signal(
      "Universal Link Opened",
      parameters: [
        "path": path,
        "scheme": urlScheme,
        "url": url.absoluteString,
        "handled": String(wasHandled)
      ]
    )
  }

  @available(iOS 26.0, *)
  var newContentView: some View {
    TabView(selection: $tabController.activeTab) {
      TodayView()
        .tag(Tab.today)
      NutritionView()
        .tag(Tab.nutrition)
      YouView()
        .tag(Tab.you)
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
  }

  var legacyContentView: some View {
    Group {
      switch tabController.activeTab {
      case .today:
        TodayView()
      case .nutrition:
        NutritionView()
      case .you:
        YouView()
      case .workouts:
        WorkoutsTabView()
      }
    }
    .chatLauncher()
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
