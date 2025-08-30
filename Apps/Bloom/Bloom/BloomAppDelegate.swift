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
    
    // Register notification preferences sync task handler  
    BGTaskScheduler.shared.register(
      forTaskWithIdentifier: "sync-notification-preferences",
      using: nil
    ) { task in
      Task {
        await BackgroundTaskScheduler.shared.syncNotificationPreferences()
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
      // Check if this is a morning report notification
      if let type = userInfo["type"] as? String, type == "morning_report" {
        // Morning report generation has been removed
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
}
