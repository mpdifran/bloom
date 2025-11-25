//
//  PeriodicPaywallManager.swift
//  Bloom
//
//  Created by Claude on 2025-11-25.
//

import Foundation
import BloomFoundation

actor PeriodicPaywallManager {
  static let shared = PeriodicPaywallManager()

  @Storage(key: "lastPaywallShownTimestamp", defaultValue: 0.0)
  private var lastPaywallShownTimestamp: Double

  private init() {}

  /// Computed property to access last shown date
  var lastPaywallShownDate: Date? {
    get {
      lastPaywallShownTimestamp == 0.0 ? nil : Date(timeIntervalSince1970: lastPaywallShownTimestamp)
    }
    set {
      lastPaywallShownTimestamp = newValue?.timeIntervalSince1970 ?? 0.0
    }
  }

  /// Checks if paywall should be shown based on eligibility conditions
  /// Returns true if all conditions are met, false otherwise
  func shouldShowPaywall() async -> Bool {
    // Check if user is subscribed
    guard await EntitlementController.shared.hasBloomPro != true else {
      // User is subscribed, don't show paywall
      return false
    }

    // Check if 14 days have passed since last paywall shown
    if let lastShownDate = lastPaywallShownDate {
      let daysSinceShown = Calendar.current.dateComponents(
        [.day],
        from: lastShownDate,
        to: Date()
      ).day ?? 0

      guard daysSinceShown >= 14 else {
        // Not enough time has passed
        return false
      }
    }

    // All conditions met
    return true
  }

  /// Updates the last shown timestamp
  func updateLastShownDate() async {
    lastPaywallShownDate = Date()
  }
}
