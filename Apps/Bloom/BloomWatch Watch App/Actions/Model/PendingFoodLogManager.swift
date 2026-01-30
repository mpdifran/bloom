//
//  PendingFoodLogManager.swift
//  BloomWatch Watch App
//
//  Created by Claude on 2026-01-30.
//

import Foundation
import BloomFoundation

/// Manages pending food log entries that need to be synced to iOS.
/// Queues entries locally when the iOS app is unavailable and syncs when connectivity is restored.
@MainActor
public final class PendingFoodLogManager {
  public static let shared = PendingFoodLogManager()

  private static let storageKey = "PendingFoodLogManager.entries"

  private(set) var pendingEntries: [WatchPendingFoodLogEntry] = []

  private init() {
    loadFromStorage()
  }

  // MARK: - Public Methods

  /// Logs a food item, attempting immediate sync or queuing for later
  @discardableResult
  func log(
    foodItemID: String,
    meal: String,
    numberOfServings: Double,
    date: Date = Date()
  ) async -> Bool {
    let entry = WatchPendingFoodLogEntry(
      foodItemID: foodItemID,
      meal: meal,
      numberOfServings: numberOfServings,
      date: date
    )

    pendingEntries.append(entry)
    saveToStorage()

    let success = await sendEntry(entry)
    if success {
      remove(id: entry.id)
    }
    return success
  }

  /// Syncs all pending entries that haven't been sent yet
  func syncPendingEntries() async {
    for entry in pendingEntries {
      let success = await sendEntry(entry)
      if success {
        remove(id: entry.id)
      }
    }
  }

  // MARK: - Private Methods

  private func sendEntry(_ entry: WatchPendingFoodLogEntry) async -> Bool {
    let message = entry.toMessage()

    guard let data = try? JSONEncoder().encode(message) else {
      return false
    }

    do {
      let responseData = try await WatchChannel.shared.send(data: data)
      let response = try JSONDecoder().decode(WatchFoodLogResponse.self, from: responseData)
      return response.success
    } catch {
      print("Failed to send food log: \(error)")
      return false
    }
  }

  private func remove(id: String) {
    pendingEntries.removeAll { $0.id == id }
    saveToStorage()
  }

  private func loadFromStorage() {
    guard let data = UserDefaults.group.data(forKey: Self.storageKey),
          let entries = try? JSONDecoder().decode([WatchPendingFoodLogEntry].self, from: data) else {
      return
    }
    pendingEntries = entries
  }

  private func saveToStorage() {
    guard let data = try? JSONEncoder().encode(pendingEntries) else { return }
    UserDefaults.group.set(data, forKey: Self.storageKey)
  }
}
