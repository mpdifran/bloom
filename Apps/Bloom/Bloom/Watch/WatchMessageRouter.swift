//
//  WatchMessageRouter.swift
//  Bloom
//
//  Created by Mark DiFranco on 2026-01-30.
//

import Foundation
import BloomFoundation
import CoreHealth
import DataContainer
import SwiftData

/// Routes all messages received from the Apple Watch to appropriate handlers
@MainActor
final class WatchMessageRouter {
  static let shared = WatchMessageRouter()

  private init() {
    setupMessageHandler()
  }

  private func setupMessageHandler() {
    Task {
      await WatchChannel.shared.setMessageHandler { data in
        await WatchMessageRouter.shared.handleMessage(data)
      }
    }
  }

  private func handleMessage(_ data: Data) async -> Data {
    // Try bowel movement message
    if let message = try? JSONDecoder.watch.decode(WatchBowelMovementMessage.self, from: data),
       message.type == WatchBowelMovementMessage.messageType {
      return await handleBowelMovement(message)
    }

    // Try reminder completion message
    if let message = try? JSONDecoder.watch.decode(WatchReminderCompletionMessage.self, from: data),
       message.type == WatchReminderCompletionMessage.messageType {
      return await handleReminderCompletion(message)
    }

    // Unknown message type
    return Data()
  }

  // MARK: - Bowel Movement Handler

  private func handleBowelMovement(_ message: WatchBowelMovementMessage) async -> Data {
    let entry = message.entry
    let success = await saveBowelMovement(entry)

    let response = WatchBowelMovementResponse(success: success, entryId: entry.id)
    return (try? JSONEncoder.watch.encode(response)) ?? Data()
  }

  private func saveBowelMovement(_ entry: WatchBowelMovementEntry) async -> Bool {
    do {
      let context = ContainerHolder.shared.createContext()

      // Check for duplicate by recordID
      let recordID = entry.id
      let descriptor = FetchDescriptor<BowelMovement>(
        predicate: #Predicate { $0.recordID == recordID }
      )

      let existing = try context.fetch(descriptor)
      if !existing.isEmpty {
        // Already exists, consider it a success
        return true
      }

      // Create and insert the bowel movement
      let duration = BowelMovement.Duration(rawValue: entry.rawDuration) ?? .between5And10Min
      let bowelMovement = BowelMovement(
        date: entry.date,
        bristolStoolType: entry.bristolStoolType,
        duration: duration,
        recordID: entry.id
      )

      context.insert(bowelMovement)
      try context.save()

      // Refresh vitals to include the new entry
      await VitalsCalculator.shared.fetchSwiftDataTypes()

      return true
    } catch {
      return false
    }
  }

  // MARK: - Reminder Completion Handler

  private func handleReminderCompletion(_ message: WatchReminderCompletionMessage) async -> Data {
    do {
      switch message.action {
      case .complete:
        try await RemindersManager.shared.markReminderCompleted(
          withID: message.reminderID,
          occurrenceID: message.occurrenceID,
          source: .manual
        )
      case .uncomplete:
        try await RemindersManager.shared.markReminderUncompleted(
          withID: message.reminderID,
          occurrenceID: message.occurrenceID
        )
      }

      // Sync updated data back to watch
      await WatchTodaySyncer.shared.syncToWatch()

      let response = WatchReminderCompletionResponse(
        success: true,
        reminderID: message.reminderID,
        isNowCompleted: message.action == .complete
      )
      return (try? JSONEncoder.watch.encode(response)) ?? Data()
    } catch {
      let response = WatchReminderCompletionResponse(
        success: false,
        reminderID: message.reminderID,
        isNowCompleted: false
      )
      return (try? JSONEncoder.watch.encode(response)) ?? Data()
    }
  }
}
