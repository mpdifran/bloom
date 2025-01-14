//
//  BloomApp.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-03-21.
//

import SwiftUI
import Bugsnag
import BugsnagPerformance
import TelemetryDeck
import DataContainer
import RevenueCat

private extension String {
  static let telemetryDeckAppID = "764D40B8-F2CE-4372-87D3-0D68F34E08CA"
  static let revenueCatPublicAPIKey = "appl_TarcsGdjyMRvzKeiDYYrxvhAZVo"
}

@main
struct BloomApp: App {

  private let foregroundPublisher = NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)

  init() {
    Bugsnag.start()
    BugsnagPerformance.start()

    // Setup TelemetryDeck
    TelemetryDeck.initialize(config: .init(appID: .telemetryDeckAppID, salt: "bloom_secret_salt"))

    // Setup RevenueCat
    #if DEBUG
    Purchases.logLevel = .debug
    #endif
    Purchases.configure(withAPIKey: .revenueCatPublicAPIKey, appUserID: UserID.value)

    // Link TelemetryDeck with RevenueCat
    Purchases.shared.attribution.setAttributes([
        "$telemetryDeckUserId": TelemetryManager.shared.hashedDefaultUser,
        "$telemetryDeckAppId": .telemetryDeckAppID
    ])
    _ = EntitlementController.shared

    Task {
      await HealthSleepObserver.shared.observeSleep()
    }

    Task {
      do {
        try await UserController.shared.verifyAuthentication()
      } catch {
        TelemetryDeck.errorOccurred(
          id: "BloomApp.verifyAuthentication",
          category: .appState,
          message: error.localizedDescription
        )
      }
    }

    //        BackgroundTaskScheduler.shared.scheduleProactiveTipTask()
  }

  @AppStorage("PreferencesView.danieleMode") private var danieleMode = false

  var body: some Scene {
    WindowGroup {
      RootView()
        .tint(.accent)
        .onReceive(foregroundPublisher) { _ in
          onForeground()
        }
        .task {
          await VitalsCalculator.shared.refreshVitals()
        }
    }
    .modelContainer(ContainerHolder.shared.container)
    //        .backgroundTask(.appRefresh("proactive-tip")) {
    //            if await danieleMode {
    //                await ProactiveTipper.shared.sendProactiveTip()
    //            }
    //            BackgroundTaskScheduler.shared.scheduleProactiveTipTask()
    //        }
  }
}

private extension BloomApp {

  func onForeground() {
    NutritionTrackingViewModel.shared.updateMealForCurrentTime()
    Task {
      await VitalsCalculator.shared.refreshVitals()
    }
  }
}
