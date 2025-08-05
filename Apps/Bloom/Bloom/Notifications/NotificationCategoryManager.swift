//
//  NotificationCategoryManager.swift
//  Bloom
//
//  Created by Assistant on 2025-08-03.
//

import Foundation
import UserNotifications
import BloomFoundation

final class NotificationCategoryManager {
  static let shared = NotificationCategoryManager()
  
  private init() {}
  
  /// Registers all notification categories with their actions
  func registerNotificationCategories() async {
    let categories = createNotificationCategories()
    UNUserNotificationCenter.current().setNotificationCategories(categories)
  }
  
  private func createNotificationCategories() -> Set<UNNotificationCategory> {
    var categories: Set<UNNotificationCategory> = []
    
    // Reminders category with Complete action
    let completeAction = UNNotificationAction(
      identifier: .ActionID.completeReminder,
      title: "Complete",
      options: [.authenticationRequired],
      icon: UNNotificationActionIcon(systemImageName: "checkmark")
    )

    let remindersCategory = UNNotificationCategory(
      identifier: .CategoryID.reminders,
      actions: [completeAction],
      intentIdentifiers: [],
      options: []
    )
    
    categories.insert(remindersCategory)
    
    return categories
  }
}
