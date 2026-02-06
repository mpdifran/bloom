//
//  PendingBowelMovementManager.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-01-27.
//

import Foundation
import BloomFoundation

@MainActor
final class PendingBowelMovementManager: ObservableObject {
  static let shared = PendingBowelMovementManager()

  private static let storageKey = "PendingBowelMovementManager.pendingEntries"
  /// Maximum age for pending entries before cleanup (7 days)
  private static let maxEntryAge: TimeInterval = 7 * 24 * 60 * 60

  @Published private(set) var pendingEntries: [WatchBowelMovementEntry] = []

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

    let confirmedIDs = Set(confirmation.confirmedBowelMovementIDs)
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

  /// Adds an entry to the pending queue and attempts to sync in the background.
  /// Returns immediately after queuing locally for instant UI response.
  func add(_ entry: WatchBowelMovementEntry) {
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

  /// Removes an entry from the pending queue
  func remove(id: String) {
    pendingEntries.removeAll { $0.id == id }
    saveToStorage()
  }

  /// Syncs all pending entries to the phone
  func syncPendingEntries() async {
    let entriesToSync = pendingEntries
    for entry in entriesToSync {
      let success = await sendEntry(entry)
      if success {
        remove(id: entry.id)
      }
    }
  }

  /// Sends a single entry to the phone via WatchChannel
  private func sendEntry(_ entry: WatchBowelMovementEntry) async -> Bool {
    let message = WatchBowelMovementMessage(entry: entry)

    guard let data = try? JSONEncoder.watch.encode(message) else {
      return false
    }

    do {
      let responseData = try await WatchChannel.shared.send(data: data)
      let response = try JSONDecoder.watch.decode(WatchBowelMovementResponse.self, from: responseData)
      return response.success && response.entryId == entry.id
    } catch {
      // Phone not reachable or other error - entry stays in queue
      return false
    }
  }

  private func loadFromStorage() {
    guard let data = UserDefaults.group.data(forKey: Self.storageKey),
          let entries = try? JSONDecoder.watch.decode([WatchBowelMovementEntry].self, from: data) else {
      return
    }
    pendingEntries = entries
  }

  private func saveToStorage() {
    guard let data = try? JSONEncoder.watch.encode(pendingEntries) else { return }
    UserDefaults.group.set(data, forKey: Self.storageKey)
  }
}
