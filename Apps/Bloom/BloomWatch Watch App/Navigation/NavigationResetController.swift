//
//  NavigationResetController.swift
//  BloomWatch Watch App
//
//  Created by Claude on 2026-02-01.
//

import Foundation

/// Shared controller to trigger navigation reset across all tabs.
/// Used when handling deep links that need to dismiss sheets and pop navigation.
@Observable @MainActor
final class NavigationResetController {
  static let shared = NavigationResetController()

  private(set) var resetTrigger = 0

  /// Set to true when bio age details should be shown after navigation.
  var shouldShowBioAgeDetails = false

  private init() {}

  /// Triggers a reset - all observing views should dismiss sheets and pop navigation.
  func reset() {
    resetTrigger += 1
  }
}
