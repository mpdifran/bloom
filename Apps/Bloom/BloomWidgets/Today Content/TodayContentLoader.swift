//
//  TodayContentLoader.swift
//  BloomWidgets
//
//  Created by Claude Code on 2025-10-24.
//

import Foundation
import BloomFoundation
import DataContainer
import CoreHealth

/// Shared utility for loading today's content from UserDefaults across widget timeline providers
enum TodayContentLoader {
  /// Represents the state of loaded today content
  enum ContentState {
    case subscriptionRequired
    case loading
    case loaded(TodayContentDTO)
  }

  /// Loads today's content from UserDefaults with subscription and freshness checks
  /// - Parameter date: The date to check content freshness against (defaults to current date)
  /// - Returns: The content state (subscription required, loading, or loaded with data)
  static func loadTodayContent(for date: Date = Date()) -> ContentState {
    // Check subscription status first
    guard checkSubscription() else {
      return .subscriptionRequired
    }

    // Try to load today's content from UserDefaults
    guard let data = UserDefaults.group.data(forKey: "TodayInsightsManager.lastTodayContentResponse"),
          let content = try? JSONDecoder().decode(TodayContentDTO.self, from: data) else {
      return .loading
    }

    // Check if content is from today
    guard Calendar.current.isDate(content.day, inSameDayAs: date) else {
      return .loading
    }

    return .loaded(content)
  }

  /// Checks if the user has an active subscription
  /// - Returns: true if subscribed, false otherwise
  static func checkSubscription() -> Bool {
    UserDefaults.group.bool(forKey: "RevenueCat.IsSubscribed")
  }

  /// Gets the user's name from UserDefaults
  /// - Returns: The user's name, or empty string if not set
  static func getUserName() -> String {
    UserDefaults.group.string(forKey: String.HealthDefaults.name.key) ?? ""
  }
}
