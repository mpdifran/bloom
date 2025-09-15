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
  private let tokenManager = PushNotificationTokenManager.shared

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

    // Note: Background task handlers are registered in AppDelegate.didFinishLaunchingWithOptions, scheduling happens in .task blocks

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
          await TrainingLoadObserver.shared.observeTrainingLoad()
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
          // Register notification categories with actions
          await NotificationCategoryManager.shared.registerNotificationCategories()
          // Schedule all reminder notifications on app launch
          await RemindersManager.shared.rescheduleAllReminders()
          // Start observing HealthKit changes for reminder triggers
          ReminderTriggerObserver.shared.startObserving()
        }
        .task {
          // Schedule background tasks - handlers are registered in AppDelegate.didFinishLaunchingWithOptions
          BackgroundTaskScheduler.shared.scheduleReminderNotificationUpdateTask()
        }
    }
    .modelContainer(ContainerHolder.shared.container)
  }
}

private extension BloomApp {

  func onForeground() {
    NutritionTrackingViewModel.shared.updateMealForCurrentTime()
    RatingPromptTracker.shared.incrementEventCount()

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
    
    Task {
      // Load Today content when app comes to foreground
      await TodayContentCoordinator.shared.loadContentIfNeeded()
    }
    
    Task {
      // Check if APNs token needs refresh
      await tokenManager.refreshTokenIfNeeded()
    }
    
    Task {
      // Sync notification preferences
      await NotificationPreferencesService.shared.syncMorningNotificationPreferences()
    }
    
    Task { @MainActor in
      // Run image resize migration in background
      ImageResizeMigration.shared.runMigrationIfNeeded()
    }

    TelemetryDeck.signal(
      "Health Goal",
      parameters: [
        "healthGoal": HealthDefaults.shared.getFocus()
      ]
    )
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
