//
//  NotificationPreferences.swift
//  Bloom
//
//  Created by Claude on 2026-01-23.
//

import Foundation
import SwiftUI

/// Manages user preferences for non-monitor notifications.
public final class NotificationPreferences: ObservableObject {

  public static let shared = NotificationPreferences()

  // MARK: - Workout Notifications

  @AppStorage("notifications.workoutCompletion.enabled")
  public var workoutCompletionEnabled: Bool = true

  // MARK: - Goal Notifications

  @AppStorage("notifications.goalAchievements.enabled")
  public var goalAchievementsEnabled: Bool = true

  private init() {}
}
