//
//  RatingPromptTracker.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-06.
//

import SwiftUI
import TelemetryDeck
import BloomFoundation

private extension Int {
  static let minPositiveEventCount = 10
  static let monthsOfPauseAfterShowingRatingPrompt = 3
}

extension String {
  static let nextRatingDate = "nextRatingDate"
  static let positiveEventCount = "positiveEventCount"
}

@MainActor
final class RatingPromptTracker {
  static let shared = RatingPromptTracker()

  @Storage(key: .positiveEventCount, defaultValue: 0) var positiveEventCount: Int
  @Storage(key: .nextRatingDate, defaultValue: nil) var nextRatingDate: Date?

  private let networkMonitor = NetworkMonitor()

  private init() { }
}

extension RatingPromptTracker {

  /// Increments the positive event count without checking if the prompt should be shown.
  func incrementEventCount() {
    guard canTrackRatingCount() else { return }
    positiveEventCount += 1
  }

  /// Returns `true` if the rating prompt should be shown to the user.
  func recordEvent() -> Bool {
    guard canTrackRatingCount() else { return false }

    positiveEventCount += 1

    guard networkMonitor.isNetworkReachable else { return false }
    guard positiveEventCount >= .minPositiveEventCount else { return false }

    nextRatingDate = Calendar.current.date(byAdding: .month, value: .monthsOfPauseAfterShowingRatingPrompt, to: .now)
    positiveEventCount = 0

    TelemetryDeck.signal("Show App Rating Prompt")

    return true
  }
}

private extension RatingPromptTracker {

  func canTrackRatingCount() -> Bool {
    guard let nextRatingDate = nextRatingDate else { return true }

    return nextRatingDate < Date.now
  }
}
