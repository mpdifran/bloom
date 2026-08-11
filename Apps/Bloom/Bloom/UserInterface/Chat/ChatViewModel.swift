//
//  ChatViewModel.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-16.
//

import SwiftUI
import BloomModel
import DataContainer
import SwiftData
import TelemetryDeck
import CoreNetwork

@Observable @MainActor
final class ChatViewModel {
  var cellModels = [ChatCellModel]()
  var error: Error?
  var conversationInProgress = false
  var shouldTriggerScroll = false

  private let conversationActor: ConversationModelActor
  private let historyModifier: ChatHistoryModifier
  private let conversationID: String

  init(conversationID: String) {
    self.conversationID = conversationID
    self.conversationActor = ConversationModelActor(modelContainer: ContainerHolder.shared.container)
    self.historyModifier = ChatHistoryModifier(conversationID: conversationID)
    setupObservers()
  }

  private var cellModelsTask: Task<Void, Never>?
  private var errorTask: Task<Void, Never>?
  private var conversationTask: Task<Void, Never>?
}

extension ChatViewModel {

  func sendMessage(
    _ message: String,
    images: [UIImage],
    chatContexts: [ChatContext]
  ) async {
    do {
      let conversation = try await conversationActor.fetchConversation(by: conversationID)
      try await ChatController.shared.send(
        message: message,
        images: images,
        chatContexts: chatContexts,
        conversationID: conversationID,
        lastMessageID: conversation?.lastMessageID
      )
    } catch {
      self.error = error
      TelemetryDeck.errorOccurred(
        id: "ChatViewModel.sendMessage",
        category: .thrownException,
        message: error.localizedDescription
      )
    }
  }

  func sendSystemContextMessage(dummyAssistantMessage: String?, systemContext: String) async {
    do {
      let conversation = try await conversationActor.fetchConversation(by: conversationID)
      try await ChatController.shared.sendSystemContextMessage(
        dummyAssistantMessage: dummyAssistantMessage,
        systemContext: systemContext,
        conversationID: conversationID,
        lastMessageID: conversation?.lastMessageID
      )
    } catch {
      self.error = error
      TelemetryDeck.errorOccurred(
        id: "ChatViewModel.sendSystemContextMessage",
        category: .thrownException,
        message: error.localizedDescription
      )
    }
  }

  func deleteChatHistory() async throws {
    try await NetworkRequester.shared.deleteChatThread()
    try await historyModifier.deleteAllMessages()
  }

  func updateMessageAction(id: String, hasPerformedAction: Bool) async {
    do {
      try await historyModifier.updateMessageAction(id: id, hasPerformedAction: hasPerformedAction)
    } catch {
      self.error = error
      TelemetryDeck.errorOccurred(
        id: "ChatViewModel.updateMessageAction",
        category: .thrownException,
        message: error.localizedDescription
      )
    }
  }
  
  func maintainWebSocketConnection() async {
    // Initial connection
    await ChatController.shared.ensureWebSocketConnected()
    
    // Monitor for disconnections and reconnect
    while !Task.isCancelled {
      if await ChatController.shared.isDisconnected {
        await ChatController.shared.reconnectWebSocket()
      }
      
      // Check every 5 seconds
      try? await Task.sleep(for: .seconds(5))
    }
  }
}

private extension ChatViewModel {

  func setupObservers() {
    cellModelsTask = Task.detached { [weak self] in
      guard let historyModifier = self?.historyModifier else { return }
      for await cellModels in await historyModifier.$cellModels {
        await MainActor.run { [weak self] in
          self?.cellModels = cellModels
        }
      }
    }
    errorTask = Task.detached { [weak self] in
      for await error in await ChatController.shared.$error {
        await MainActor.run { [weak self] in
          self?.error = error

          if let error {
            TelemetryDeck.errorOccurred(
              id: "ChatViewModel.ChatController.errorTask",
              category: .thrownException,
              message: error.localizedDescription
            )
          }
        }
      }
    }
    conversationTask = Task.detached { [weak self] in
      for await conversationInProgressDict in await ChatController.shared.$conversationInProgress {
        await MainActor.run { [weak self] in
          guard let self else { return }
          self.conversationInProgress = conversationInProgressDict[conversationID] ?? false
        }
      }
    }

    // Observe lastMessageID updates from the server
    Task.detached { [weak self] in
      for await update in await ChatController.shared.$lastMessageIDUpdate {
        guard let self, let update else { continue }
        // Only process updates for this conversation
        guard update.conversationID == self.conversationID else { continue }

        // Update the conversation's lastMessageID
        do {
          _ = try await self.conversationActor.updateConversationLastMessageID(
            conversationID: update.conversationID,
            lastMessageID: update.lastMessageID
          )
        } catch {
          // Log error but don't propagate to UI
          await MainActor.run {
            TelemetryDeck.errorOccurred(
              id: "ChatViewModel.lastMessageIDUpdate",
              category: .thrownException,
              message: error.localizedDescription
            )
          }
        }
      }
    }
  }
}
