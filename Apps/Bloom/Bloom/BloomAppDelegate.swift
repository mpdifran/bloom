//
//  BloomAppDelegate.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-14.
//

import UIKit
import TelemetryDeck
import BloomModel

class BloomAppDelegate: NSObject, UIApplicationDelegate {

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    return true
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
