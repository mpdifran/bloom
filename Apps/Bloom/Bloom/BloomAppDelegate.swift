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
      // Check if this is a test notification
      if let type = userInfo["type"] as? String,
         type == "test_notification" {
        await handleTestNotification(userInfo: userInfo)
        return .newData
      }

      // Check if this is a magic scanner completion notification
      if let type = userInfo["type"] as? String,
         type == MagicScanCompleteTrigger.notificationType {
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

  @MainActor
  private func handleTestNotification(userInfo: [AnyHashable: Any]) async {
    let timestamp = userInfo["timestamp"] as? String ?? "Unknown"

    // Find the root view controller to present the alert
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let rootViewController = windowScene.windows.first?.rootViewController else {
      print("Test notification received at \(timestamp), but could not present alert")
      return
    }

    // Find the topmost view controller
    var topController = rootViewController
    while let presented = topController.presentedViewController {
      topController = presented
    }

    let alert = UIAlertController(
      title: "Test Push Notification Received",
      message: "Silent push notification received successfully!\n\nTimestamp: \(timestamp)",
      preferredStyle: .alert
    )

    alert.addAction(UIAlertAction(title: "OK", style: .default))

    topController.present(alert, animated: true)

    TelemetryDeck.signal("test_push_notification_received", parameters: ["timestamp": timestamp])
  }
}
