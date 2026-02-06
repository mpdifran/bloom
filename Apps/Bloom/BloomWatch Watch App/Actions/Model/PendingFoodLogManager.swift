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
  /// Maximum age for pending entries before cleanup (7 days)
  private static let maxEntryAge: TimeInterval = 7 * 24 * 60 * 60

  private(set) var pendingEntries: [WatchPendingFoodLogEntry] = []

  private init() {
    loadFromStorage()
    cleanupStaleEntries()
    checkForConfirmations()

    // Listen for application context updates (backup confirmation)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleApplicationContextUpdate),
      name: WatchChannel.applicationContextDidUpdate,
      object: nil
    )
  }

  @objc private func handleApplicationContextUpdate() {
    checkForConfirmations()
  }

  /// Checks for confirmed IDs in application context and removes matching entries
  private func checkForConfirmations() {
    guard let data = WatchChannel.shared.getApplicationContextData(for: WatchChannel.confirmationDataKey),
          let confirmation = try? JSONDecoder.watch.decode(WatchConfirmationData.self, from: data) else {
      return
    }

    let confirmedIDs = Set(confirmation.confirmedFoodLogIDs)
    let entriesToRemove = pendingEntries.filter { confirmedIDs.contains($0.id) }

    for entry in entriesToRemove {
      remove(id: entry.id)
    }
  }

  /// Cleans up entries older than maxEntryAge to prevent cache bloat
  private func cleanupStaleEntries() {
    let cutoffDate = Date().addingTimeInterval(-Self.maxEntryAge)
    let staleEntries = pendingEntries.filter { $0.date < cutoffDate }

    for entry in staleEntries {
      remove(id: entry.id)
    }
  }

  // MARK: - Public Methods

  /// Logs a food item, queuing locally and syncing in the background.
  /// Returns immediately after queuing for instant UI response.
  func log(
    foodItemID: String,
    meal: String,
    numberOfServings: Double,
    date: Date = Date()
  ) {
    let entry = WatchPendingFoodLogEntry(
      foodItemID: foodItemID,
      meal: meal,
      numberOfServings: numberOfServings,
      date: date
    )

    pendingEntries.append(entry)
    saveToStorage()

    // Fire-and-forget sync attempt - UI doesn't wait for this
    Task {
      let success = await sendEntry(entry)
      if success {
        await MainActor.run { [weak self] in
          self?.remove(id: entry.id)
        }
      }
    }
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

  /// Logs a saved meal (not queued for offline, requires connectivity)
  @discardableResult
  func logMeal(
    mealRecordID: String,
    meal: String,
    date: Date = Date()
  ) async -> Bool {
    let message = WatchMealLogMessage(
      mealRecordID: mealRecordID,
      meal: meal,
      date: date
    )

    guard let data = try? JSONEncoder.watch.encode(message) else {
      return false
    }

    do {
      let responseData = try await WatchChannel.shared.send(data: data)
      let response = try JSONDecoder.watch.decode(WatchFoodLogResponse.self, from: responseData)
      return response.success
    } catch {
      print("Failed to send meal log: \(error)")
      return false
    }
  }

  // MARK: - Private Methods

  private func sendEntry(_ entry: WatchPendingFoodLogEntry) async -> Bool {
    let message = entry.toMessage()

    guard let data = try? JSONEncoder.watch.encode(message) else {
      return false
    }

    do {
      let responseData = try await WatchChannel.shared.send(data: data)
      let response = try JSONDecoder.watch.decode(WatchFoodLogResponse.self, from: responseData)
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
          let entries = try? JSONDecoder.watch.decode([WatchPendingFoodLogEntry].self, from: data) else {
      return
    }
    pendingEntries = entries
  }

  private func saveToStorage() {
    guard let data = try? JSONEncoder.watch.encode(pendingEntries) else { return }
    UserDefaults.group.set(data, forKey: Self.storageKey)
  }
}
