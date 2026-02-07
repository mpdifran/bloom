//
//  PendingReminderCompletionManager.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-01-30.
//

import Foundation
import BloomFoundation
import WatchKit

@MainActor
final class PendingReminderCompletionManager: ObservableObject {
  static let shared = PendingReminderCompletionManager()

  private static let storageKey = "PendingReminderCompletionManager.pendingCompletions"
  private static let widgetQueueKey = "WidgetPendingReminderCompletions"

  @Published private(set) var pendingCompletions: [WatchReminderCompletionMessage] = []

  private init() {
    loadFromStorage()
  }

  /// Attempts to complete/uncomplete a reminder, queuing if phone unavailable
  func complete(
    reminderID: String,
    occurrenceID: String,
    action: WatchReminderCompletionMessage.CompletionAction
  ) async -> Bool {
    let message = WatchReminderCompletionMessage(
      reminderID: reminderID,
      occurrenceID: occurrenceID,
      action: action
    )

    // Optimistically update local state
    let isCompleted = action == .complete
    TodayProvider.shared.updateReminderOptimistically(
      reminderID: reminderID,
      occurrenceID: occurrenceID,
      isCompleted: isCompleted
    )

    // Play feedback
    if isCompleted {
      WKInterfaceDevice.current().play(.success)
    } else {
      WKInterfaceDevice.current().play(.click)
    }

    // Try to send to phone
    let success = await sendCompletion(message)

    if !success {
      // Queue for later
      pendingCompletions.append(message)
      saveToStorage()
    }

    return success
  }

  /// Consumes completions queued by the widget extension and attempts to sync them to the phone
  func consumeWidgetQueuedCompletions() async {
    guard let data = UserDefaults.group.data(forKey: Self.widgetQueueKey),
          let widgetCompletions = try? JSONDecoder.watch.decode(
            [WatchReminderCompletionMessage].self, from: data
          ),
          !widgetCompletions.isEmpty else {
      return
    }

    // Clear the widget queue immediately to prevent double-processing
    UserDefaults.group.removeObject(forKey: Self.widgetQueueKey)

    for completion in widgetCompletions {
      let success = await sendCompletion(completion)
      if !success {
        pendingCompletions.append(completion)
        saveToStorage()
      }
    }
  }

  /// Syncs all pending completions to the phone
  func syncPendingCompletions() async {
    let completionsToSync = pendingCompletions
    for completion in completionsToSync {
      let success = await sendCompletion(completion)
      if success {
        remove(completion)
      }
    }
  }

  private func sendCompletion(_ message: WatchReminderCompletionMessage) async -> Bool {
    guard let data = try? JSONEncoder.watch.encode(message) else {
      return false
    }

    do {
      let responseData = try await WatchChannel.shared.send(data: data)
      let response = try JSONDecoder.watch.decode(WatchReminderCompletionResponse.self, from: responseData)
      return response.success && response.reminderID == message.reminderID
    } catch {
      // Phone not reachable
      return false
    }
  }

  private func remove(_ message: WatchReminderCompletionMessage) {
    pendingCompletions.removeAll {
      $0.reminderID == message.reminderID &&
      $0.occurrenceID == message.occurrenceID
    }
    saveToStorage()
  }

  private func loadFromStorage() {
    guard let data = UserDefaults.group.data(forKey: Self.storageKey),
          let completions = try? JSONDecoder.watch.decode([WatchReminderCompletionMessage].self, from: data) else {
      return
    }
    pendingCompletions = completions
  }

  private func saveToStorage() {
    guard let data = try? JSONEncoder.watch.encode(pendingCompletions) else { return }
    UserDefaults.group.set(data, forKey: Self.storageKey)
  }
}
