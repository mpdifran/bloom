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
import HealthKit

@main
struct BloomApp: App {

  @UIApplicationDelegateAdaptor(BloomAppDelegate.self) var appDelegate

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
    HealthDefaults.migrateFromLegacyKeys()

    // Listen for workouts starting from Apple Watch
    WorkoutManager.shared.setupRemoteSessionHandler()
  }

  var body: some Scene {
    WindowGroup {
      RootView()
        .tint(.accent)
        .onForeground {
          NutritionTrackingViewModel.shared.updateMealForCurrentTime()
          RatingPromptTracker.shared.incrementEventCount()
        }
        .onForegroundTask {
          await UserController.shared.identify()
        }
        .onForegroundTask {
          await tokenManager.refreshTokenIfNeeded()
        }
        .onForegroundTask {
          await VitalsCalculator.shared.refreshVitals()
        }
        .onForegroundTask {
          await YouStatsCalculator.shared.refreshStats()
        }
        .onForegroundTask {
          await TodayInsightsManager.shared.refreshContentIfNeeded()
        }
        .onForegroundTask {
          await BiologicalAgeViewModel.shared.calculateBiologicalAgeIfNeeded()
        }
        .onForegroundTask {
          await RemindersManager.shared.rescheduleAllReminders()
          ReminderTriggerObserver.shared.startObserving()
        }
        .onForegroundTask {
          await PeriodPredictionScheduler.shared.schedulePeriodPredictionNotifications()
        }
        .onForegroundTask {
          TelemetryDeck.signal(
            "Health Goal",
            parameters: ["healthGoal": HealthDefaults.shared.getFocus()]
          )
        }
        .onForegroundTask { @MainActor in
          await ReEngagementScheduler.shared.scheduleNotificationIfNeeded()
        }
        .onForegroundTask {
          let modelContext = ModelContext(ContainerHolder.shared.container)
          await GoalWidgetCacheManager.shared.updateCache(modelContext: modelContext)
        }
        .onForegroundTask {
          await SalesManager.shared.refreshSalesIfNeeded()
        }
        .task {
          let modelContext = ModelContext(ContainerHolder.shared.container)
          await GoalWidgetHealthObserver.shared.startObserving(modelContext: modelContext)
        }
        .task {
          await HealthSleepObserver.shared.observeSleep()
        }
        .task {
          await TrainingLoadObserver.shared.observeTrainingLoad()
        }
        .task {
          await StepsObserver.shared.startObserving()
        }
        .task {
          await NotificationCategoryManager.shared.registerNotificationCategories()
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
          ChatConversationMigration.shared.runMigrationIfNeeded()
        }
        .task {
          PngToJpegMigration.shared.runMigrationIfNeeded()
        }
        .task { @MainActor in
          ImageResizeMigration.shared.runMigrationIfNeeded()
        }
    }
    .modelContainer(ContainerHolder.shared.container)
  }
}

private extension BloomApp {

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
