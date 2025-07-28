//
//  NotificationPreferencesService.swift
//  Bloom
//
//  Created by Assistant on 2025-07-27.
//

import Foundation
import BloomModel

@MainActor
final class NotificationPreferencesService {
  static let shared = NotificationPreferencesService()
  
  private let userController = UserController.shared
  private let networkRequester = NetworkRequester.shared

  private let lastSyncKey = "NotificationPreferencesService.lastSync"
  
  private init() {}
  
  /// Syncs morning notification preferences with the server
  func syncMorningNotificationPreferences() async {
    guard userController.isAuthenticated else {
      print("User not authenticated, skipping notification preferences sync")
      return
    }
    
    // Check if we've synced recently (within 24 hours)
    if let lastSync = UserDefaults.group.object(forKey: lastSyncKey) as? Date,
       Date().timeIntervalSince(lastSync) < 24 * 60 * 60 {
      print("Already synced within 24 hours, skipping")
      return
    }
    
    let viewModel = ReportCoordinatorViewModel.shared
    let calendar = Calendar.current
    let components = calendar.dateComponents([.hour, .minute], from: viewModel.morningReportDate)
    
    guard let hour = components.hour,
          let minute = components.minute else {
      print("Failed to extract hour and minute from morning report date")
      return
    }
    
    let timeZone = TimeZone.current.identifier
    
    // Round minute to nearest 5
    let roundedMinute = Int((Double(minute) / 5.0).rounded()) * 5
    
    do {
      try await networkRequester.updateMorningNotificationTime(
        hour: hour,
        minute: roundedMinute,
        timeZone: timeZone
      )

      // Update last sync time
      UserDefaults.group.set(Date(), forKey: lastSyncKey)
      
      print("Successfully synced notification preferences - \(hour):\(String(format: "%02d", roundedMinute)) \(timeZone)")
    } catch {
      print("Failed to sync notification preferences: \(error)")
    }
  }
  
  /// Force sync, ignoring the 24-hour limit
  func forceSyncMorningNotificationPreferences() async {
    UserDefaults.group.removeObject(forKey: lastSyncKey)
    await syncMorningNotificationPreferences()
  }
}
