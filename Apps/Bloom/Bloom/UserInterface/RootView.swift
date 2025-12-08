//
//  RootView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-09.
//

import SwiftUI
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
  @State private var presentedPaywall: AnyView?

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
          switch experimentManager.variant(for: .onboardingFeaturePitch) {
          case .treatment:
            OnboardingRootViewTreatment {
              withAnimation {
                hasShownOnboarding = true
              }
            }
          case .control:
            OnboardingRootView {
              withAnimation {
                hasShownOnboarding = true
              }
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
    .fullScreenCover($presentedPaywall)
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
    .task {
      // Check periodic paywall experiment on app launch
      await checkPeriodicPaywall()

      // Check for active sales
      await checkAndShowSale()
    }
    .onForeground {
      Task {
        await MagicScanStatusChecker.shared.checkPendingItems(modelContext: modelContext)
        await BiologicalAgeStatusChecker.shared.checkPendingCalculation()
        await ConsentManager.shared.syncPendingConsentIfNeeded()
      }

      Task {
        // Check periodic paywall experiment on foreground
        await checkPeriodicPaywall()
      }

      Task {
        // Check for active sales
        await checkAndShowSale()
      }

      Task {
        // Check for unknown consent states
        if await ConsentManager.shared.hasUnknownConsentStates() {
          presentedSheet = PrivacyUnknownOptInView().asAny
        }
      }
    }
    .onOpenURL { url in
      handleURL(url)
    }
    .tint(themeController.theme.color)
    .environment(themeController)
    .environment(experimentManager)
    .environment(tabController)
  }
}

private extension RootView {

  func checkPeriodicPaywall() async {
    guard hasShownOnboarding else { return }

    let variant = experimentManager.variant(for: .periodicPaywall)
    let shouldShow = await PeriodicPaywallManager.shared.shouldShowPaywall()

    switch variant {
    case .treatment:
      if shouldShow {
        TelemetryDeck.signal("AB: Periodic Paywall v3 - Treatment")
        EntitledAction(presentedSheet: $presentedSheet) {
          // Do nothing
        }
      }
    case .control:
      if shouldShow {
        TelemetryDeck.signal("AB: Periodic Paywall v3 - Control")
      }
    }
  }

  func checkAndShowSale() async {
    guard hasShownOnboarding else { return }
    guard userController.isAuthenticated else { return }

    // TODO: Enable this when we're ready
//    if let sale = await SalesManager.shared.shouldShowSale() {
//      presentedSheet = SaleModalView(sale: sale).asAny
//
//      Task {
//        await SalesManager.shared.markSaleAsShown(sale.id)
//      }
//    }
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
    presentedPaywall = nil
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
      case "biologicalAge":
        focus = .biologicalAge
      default:
        focus = .standard
      }

      EntitledAction(presentedSheet: $presentedPaywall, focus: focus) {
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
      tabController.activeTab = .vitals
      Delay(600) {
        tabController.pendingVitalNavigation = .sleepQuality
      }
    case "/vital/activity-level":
      tabController.activeTab = .vitals
      Delay(600) {
        tabController.pendingVitalNavigation = .activityLevel
      }
    case "/vital/heart-health":
      tabController.activeTab = .vitals
      Delay(600) {
        tabController.pendingVitalNavigation = .heartHealth
      }
    case "/vital/body-composition":
      tabController.activeTab = .vitals
      Delay(600) {
        tabController.pendingVitalNavigation = .bodyComposition
      }
    case "/vital/stress-levels":
      tabController.activeTab = .vitals
      Delay(600) {
        tabController.pendingVitalNavigation = .stressLevels
      }
    case "/vital/nutrition":
      tabController.activeTab = .vitals
      Delay(600) {
        tabController.pendingVitalNavigation = .nutrition
      }
    case "/vital/exercise-effectiveness":
      tabController.activeTab = .vitals
      Delay(600) {
        tabController.pendingVitalNavigation = .exerciseEffectiveness
      }
    case "/vital/cycle-tracking":
      tabController.activeTab = .vitals
      Delay(600) {
        tabController.pendingVitalNavigation = .cycleTracking
      }
    case "/vital/bowel-movements":
      tabController.activeTab = .vitals
      Delay(600) {
        tabController.pendingVitalNavigation = .bowelMovements
      }
    case "/vital/cardio-fitness":
      tabController.activeTab = .vitals
      Delay(600) {
        tabController.pendingVitalNavigation = .cardioFitness
      }
    case "/nutrition":
      tabController.activeTab = .nutrition
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
