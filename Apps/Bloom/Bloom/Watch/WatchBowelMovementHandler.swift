//
//  WatchBowelMovementHandler.swift
//  Bloom
//
//  Created by Mark DiFranco on 2026-01-27.
//

import Foundation
import BloomFoundation
import CoreHealth
import DataContainer
import SwiftData

/// Handles bowel movement messages received from the Apple Watch
@MainActor
final class WatchBowelMovementHandler {
  static let shared = WatchBowelMovementHandler()

  private init() {
    setupMessageHandler()
  }

  private func setupMessageHandler() {
    Task {
      await WatchChannel.shared.setMessageHandler { data in
        await WatchBowelMovementHandler.shared.handleMessage(data)
      }
    }
  }

  private func handleMessage(_ data: Data) async -> Data {
    // Try to decode as bowel movement message
    guard let message = try? JSONDecoder.watch.decode(WatchBowelMovementMessage.self, from: data),
          message.type == WatchBowelMovementMessage.messageType else {
      // Not a bowel movement message, return empty response
      return Data()
    }

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
}

