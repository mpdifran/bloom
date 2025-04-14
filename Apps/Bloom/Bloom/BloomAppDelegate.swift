//
//  BloomAppDelegate.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-14.
//

import UIKit

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
    let token = deviceToken
      .map({ data in String(format: "%02.2hhx", data) })
      .joined()

    
  }

  func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: any Error
  ) {

  }
}
