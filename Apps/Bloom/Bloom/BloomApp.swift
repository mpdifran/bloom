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
import BloomFoundation
import SwiftData

@main
struct BloomApp: App {

  @UIApplicationDelegateAdaptor(BloomAppDelegate.self) var appDelegate

  private let foregroundPublisher = NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
  private let tokenManager = PushNotificationTokenManager.shared

  init() {
    Bugsnag.start()
    BugsnagPerformance.start()

    // Setup TelemetryDeck
    TelemetryDeck.initialize(
      config: TelemetryManagerConfiguration(
        appID: .telemetryDeckAppID,
        salt: .telemetryDeckSalt
      )
    )

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
          await BiologicalAgeViewModel.shared.calculateBiologicalAgeIfNeeded()
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
          // Schedule period prediction notifications
          await PeriodPredictionScheduler.shared.schedulePeriodPredictionNotifications()
        }
        .task {
          // Run chat conversation migration on app launch
          ChatConversationMigration.shared.runMigrationIfNeeded()
        }
        .task {
          // Run PNG to JPEG migration on app launch
          PngToJpegMigration.shared.runMigrationIfNeeded()
        }
        .task {
          // Update goal widget cache on app launch
          let modelContext = ModelContext(ContainerHolder.shared.container)
          await GoalWidgetCacheManager.shared.updateCache(modelContext: modelContext)
        }
        .task {
          // Start observing health data changes for goal widgets
          let modelContext = ModelContext(ContainerHolder.shared.container)
          await GoalWidgetHealthObserver.shared.startObserving(modelContext: modelContext)
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
      // Reschedule period prediction notifications when app comes to foreground
      await PeriodPredictionScheduler.shared.schedulePeriodPredictionNotifications()
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
      // Calculate biological age if needed (once every 3 days)
      await BiologicalAgeViewModel.shared.calculateBiologicalAgeIfNeeded()
    }

    Task { @MainActor in
      // Run image resize migration in background
      ImageResizeMigration.shared.runMigrationIfNeeded()
    }

    Task { @MainActor in
      // Run PNG to JPEG migration in background
      PngToJpegMigration.shared.runMigrationIfNeeded()
    }

    Task { @MainActor in
      // Run chat conversation migration in background
      ChatConversationMigration.shared.runMigrationIfNeeded()
    }

    Task { @MainActor in
      // Update goal widget cache
      let modelContext = ModelContext(ContainerHolder.shared.container)
      await GoalWidgetCacheManager.shared.updateCache(modelContext: modelContext)
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
