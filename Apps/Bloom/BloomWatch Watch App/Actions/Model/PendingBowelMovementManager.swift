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

  @Published private(set) var pendingEntries: [WatchBowelMovementEntry] = []

  private init() {
    loadFromStorage()
  }

  /// Adds an entry to the pending queue and attempts to sync immediately
  func add(_ entry: WatchBowelMovementEntry) async -> Bool {
    pendingEntries.append(entry)
    saveToStorage()

    // Attempt to send immediately
    let success = await sendEntry(entry)
    if success {
      remove(id: entry.id)
    }
    return success
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
