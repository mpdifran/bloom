//
//  ChatConversationMigration.swift
//  Bloom
//
//  Created by Assistant on 2025-10-09.
//

import Foundation
import SwiftData
import DataContainer
import BloomFoundation

final class ChatConversationMigration: @unchecked Sendable {
  static let shared = ChatConversationMigration()

  @Storage(key: "chatConversationMigrationCompleted", defaultValue: false)
  private var migrationCompleted: Bool

  private init() {}

  @MainActor
  func runMigrationIfNeeded() {
    print("ChatConversationMigration: runMigrationIfNeeded called - migrationCompleted: \(migrationCompleted)")
    guard !migrationCompleted else {
      print("ChatConversationMigration: Skipping - already completed")
      return
    }

    Task.detached { [weak self] in
      await self?.performMigration()
    }
  }

  @MainActor
  func resetMigration() {
    migrationCompleted = false
  }

  func forceMigration() async {
    await performMigration()
  }

  private func performMigration() async {
    print("ChatConversationMigration: Starting migration")
    let conversationActor = ConversationModelActor(modelContainer: ContainerHolder.shared.container)

    do {
      // Step 1: Fix unassigned messages - move them to legacy conversation
      try await conversationActor.fixUnassignedMessages()

      // Step 2: Delete empty conversations
      let deletedCount = try await deleteEmptyConversations(conversationActor: conversationActor)

      // Mark as complete on main thread
      await MainActor.run {
        migrationCompleted = true
        print("ChatConversationMigration: COMPLETED")
      }
    } catch {
      print("ChatConversationMigration: ERROR - \(error)")
    }
  }

  private func deleteEmptyConversations(conversationActor: ConversationModelActor) async throws -> Int {
    // Fetch all conversations
    let conversations = try await conversationActor.fetchAllConversations()
    var deletedCount = 0

    for conversation in conversations {
      // Skip the legacy conversation - we never want to delete it
      guard conversation.id != .legacyConversationID else { continue }

      // Fetch messages for this conversation
      let messages = try await conversationActor.fetchMessagesForConversation(conversationID: conversation.id)

      // If no messages, delete the conversation
      if messages.isEmpty {
        print("ChatConversationMigration: Deleting empty conversation: \(conversation.name) (\(conversation.id))")
        try await conversationActor.deleteConversation(conversationID: conversation.id)
        deletedCount += 1
      }
    }

    return deletedCount
  }
}
