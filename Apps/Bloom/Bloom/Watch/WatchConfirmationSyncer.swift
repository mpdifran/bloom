//
//  WatchConfirmationSyncer.swift
//  Bloom
//
//  Created by Claude on 2026-02-05.
//

import Foundation
import BloomFoundation

/// Syncs confirmation data to the Apple Watch via application context.
/// This provides a backup mechanism for cache clearing when direct message responses are lost.
@MainActor
final class WatchConfirmationSyncer {
  static let shared = WatchConfirmationSyncer()

  /// Maximum number of confirmed IDs to keep (prevents unbounded growth)
  private static let maxConfirmedIDs = 50

  private var confirmedBowelMovementIDs: [String] = []
  private var confirmedFoodLogIDs: [String] = []

  private init() {
    loadFromStorage()
  }

  // MARK: - Public Methods

  /// Confirms that a bowel movement entry was successfully saved
  func confirmBowelMovement(id: String) async {
    guard !confirmedBowelMovementIDs.contains(id) else { return }

    confirmedBowelMovementIDs.append(id)

    // Keep only the most recent IDs to prevent unbounded growth
    if confirmedBowelMovementIDs.count > Self.maxConfirmedIDs {
      confirmedBowelMovementIDs = Array(confirmedBowelMovementIDs.suffix(Self.maxConfirmedIDs))
    }

    saveToStorage()
    await syncToWatch()
  }

  /// Confirms that a food log entry was successfully saved
  func confirmFoodLog(id: String) async {
    guard !confirmedFoodLogIDs.contains(id) else { return }

    confirmedFoodLogIDs.append(id)

    // Keep only the most recent IDs to prevent unbounded growth
    if confirmedFoodLogIDs.count > Self.maxConfirmedIDs {
      confirmedFoodLogIDs = Array(confirmedFoodLogIDs.suffix(Self.maxConfirmedIDs))
    }

    saveToStorage()
    await syncToWatch()
  }

  // MARK: - Private Methods

  private func syncToWatch() async {
    #if os(iOS)
    let data = WatchConfirmationData(
      confirmedBowelMovementIDs: confirmedBowelMovementIDs,
      confirmedFoodLogIDs: confirmedFoodLogIDs
    )

    guard let encoded = try? JSONEncoder.watch.encode(data) else {
      return
    }

    do {
      try await WatchChannel.shared.updateApplicationContext(
        key: WatchChannel.confirmationDataKey,
        data: encoded
      )
    } catch {
      // Silent failure - will retry on next confirmation
    }
    #endif
  }

  // MARK: - Storage

  private static let storageKey = "WatchConfirmationSyncer.data"

  private func loadFromStorage() {
    guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
          let confirmation = try? JSONDecoder().decode(WatchConfirmationData.self, from: data) else {
      return
    }

    confirmedBowelMovementIDs = confirmation.confirmedBowelMovementIDs
    confirmedFoodLogIDs = confirmation.confirmedFoodLogIDs
  }

  private func saveToStorage() {
    let data = WatchConfirmationData(
      confirmedBowelMovementIDs: confirmedBowelMovementIDs,
      confirmedFoodLogIDs: confirmedFoodLogIDs
    )

    guard let encoded = try? JSONEncoder().encode(data) else { return }
    UserDefaults.standard.set(encoded, forKey: Self.storageKey)
  }
}
