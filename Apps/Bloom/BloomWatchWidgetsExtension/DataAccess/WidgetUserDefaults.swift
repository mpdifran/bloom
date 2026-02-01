//
//  WidgetUserDefaults.swift
//  BloomWatchWidgetsExtension
//
//  Created by Claude on 2026-01-31.
//

import Foundation

/// Provides access to the shared app group UserDefaults for widget data access.
enum WidgetUserDefaults {
  /// The shared UserDefaults instance for the app group.
  /// Widgets read data from this store that the watch app writes.
  static let shared: UserDefaults = {
    guard let suiteName = Bundle.main.object(forInfoDictionaryKey: "BLOOM_APP_GROUP_ID") as? String,
          let defaults = UserDefaults(suiteName: suiteName) else {
      // Fallback to standard if app group not configured
      return .standard
    }
    return defaults
  }()
}
