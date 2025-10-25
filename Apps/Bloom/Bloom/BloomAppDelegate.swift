//
//  BloomAppDelegate.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-14.
//

import UIKit
import TelemetryDeck
import BloomModel
import BackgroundTasks

class BloomAppDelegate: NSObject, UIApplicationDelegate {

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    // Register background task handlers before app finishes launching
    registerBackgroundTasks()
    BackgroundTaskScheduler.shared.scheduleReminderNotificationUpdateTask()
    return true
  }
  
  private func registerBackgroundTasks() {
    // Register reminder notification update task handler
    BGTaskScheduler.shared.register(
      forTaskWithIdentifier: "update-reminder-notifications",
      using: nil
    ) { task in
      Task {
        await BackgroundTaskScheduler.shared.updateReminderNotifications()
        task.setTaskCompleted(success: true)
      }
    }
  }

  func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Task {
      await PushNotificationTokenManager.shared.handleNewToken(deviceToken)
    }
  }

  func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: any Error
  ) {
    PushNotificationTokenManager.shared.handleFailedRegistration(error)
    
    TelemetryDeck.errorOccurred(
      id: "BloomAppDelegate.didFailToRegisterForRemoteNotificationsWithError",
      category: .thrownException,
      message: error.localizedDescription
    )
    print(error)
  }

  func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any]
  ) async -> UIBackgroundFetchResult {
    do {
      // Check if this is a magic scanner completion notification
      if let type = userInfo["type"] as? String, type == "magic_scan_complete" {
        await handleMagicScanComplete(userInfo: userInfo)
        return .newData
      }

      // Otherwise handle as chat notification
      let data = try JSONSerialization.data(withJSONObject: userInfo, options: [])
      await ChatController.shared.handlePushData(data)

      return .newData
    } catch {
      TelemetryDeck.errorOccurred(
        id: "BloomAppDelegate.didReceiveRemoteNotification",
        category: .thrownException,
        message: error.localizedDescription
      )
      print("Error decoding push payload:", error)
      return .failed
    }
  }

  private func handleMagicScanComplete(userInfo: [AnyHashable: Any]) async {
    guard let processingIdentifier = userInfo["processingIdentifier"] as? String else {
      return
    }

    await MagicScanStatusChecker.shared.checkStatus(
      processingIdentifiers: [AIFoodProcessingIdentifier(processingIdentifier)]
    )
  }
}
