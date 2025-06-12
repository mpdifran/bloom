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
import CoreHealth

private extension String {
  static let telemetryDeckAppID = "764D40B8-F2CE-4372-87D3-0D68F34E08CA"
}

@main
struct BloomApp: App {

  @UIApplicationDelegateAdaptor(BloomAppDelegate.self) var appDelegate

  private let foregroundPublisher = NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)

  init() {
    Bugsnag.start()
    BugsnagPerformance.start()

    // Setup TelemetryDeck
    TelemetryDeck.initialize(config: TelemetryManagerConfiguration(appID: .telemetryDeckAppID, salt: "bloom_secret_salt"))

    // Setup RevenueCat
    Purchases.configure()
    Purchases.logLevel = .warn

    // Link TelemetryDeck with RevenueCat
    Purchases.shared.attribution.setAttributes([
        "$telemetryDeckUserId": TelemetryManager.shared.hashedDefaultUser,
        "$telemetryDeckAppId": .telemetryDeckAppID
    ])
    _ = EntitlementController.shared

    // Note: Background task scheduling moved to .task block to ensure handlers are registered first

    checkRegisterForRemoteNotifications()
    NotificationManager.shared.removeAllScheduledNotifications()
    migrateUserDefaults()

    // Listen for workouts starting from Apple Watch
    WorkoutManager.shared.setupRemoteSessionHandler()
  }

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
        .task {
          await HealthSleepObserver.shared.observeSleep()
        }
        .task {
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
        .task {
          // Schedule all reminder notifications on app launch
          await RemindersManager.shared.rescheduleAllReminders()
        }
        .task {
          // Schedule background tasks after handlers are registered
          BackgroundTaskScheduler.shared.scheduleReminderNotificationUpdateTask()
        }
    }
    .modelContainer(ContainerHolder.shared.container)
    .backgroundTask(.appRefresh("update-reminder-notifications")) {
        await BackgroundTaskScheduler.shared.updateReminderNotifications()
    }
  }
}

private extension BloomApp {

  func onForeground() {
    NutritionTrackingViewModel.shared.updateMealForCurrentTime()

    Task {
      await UserController.shared.identify()
    }

    Task {
      await VitalsCalculator.shared.refreshVitals()
    }

    Task {
      // Reschedule reminders when app comes to foreground
      await RemindersManager.shared.rescheduleAllReminders()
    }

    TelemetryDeck.signal(
      "Health Goal",
      parameters: [
        "healthGoal": HealthDefaults.shared.getFocus()
      ]
    )
  }

  func checkRegisterForRemoteNotifications() {
    guard UserController.shared.isAuthenticated else { return }

    UIApplication.shared.registerForRemoteNotifications()
  }

  func migrateUserDefaults() {
    let keys = UserDefaults.legacyGroup.dictionaryRepresentation().keys

    for key in keys {
      if
        UserDefaults.group.value(forKey: key) == nil,
        let value = UserDefaults.legacyGroup.value(forKey: key)
      {
        UserDefaults.group.set(value, forKey: key)
        UserDefaults.legacyGroup.removeObject(forKey: key)
      }
    }
  }
}
