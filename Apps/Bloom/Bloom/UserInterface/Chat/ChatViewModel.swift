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

@Observable @MainActor
final class ChatViewModel {
  var cellModels = [ChatCellModel]()
  var error: Error?
  var conversationInProgress = false
  var shouldTriggerScroll = false

  init() {
    setupObservers()
  }

  private var cellModelsTask: Task<Void, Never>?
  private var errorTask: Task<Void, Never>?
  private var conversationTask: Task<Void, Never>?
}

extension ChatViewModel {

  func sendMessage(
    _ message: String,
    image: UIImage?,
    chatContexts: [ChatContext]
  ) async {
    do {
      try await ChatController.shared.send(
        message: message,
        image: image,
        chatContexts: chatContexts
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

  func deleteChatHistory() async throws {
    try await NetworkRequester.shared.deleteChatThread()
    try await ChatHistoryModifier.shared.deleteAllMessages()
  }
  
  func updateMessageAction(id: String, hasPerformedAction: Bool) async {
    do {
      try await ChatHistoryModifier.shared.updateMessageAction(id: id, hasPerformedAction: hasPerformedAction)
    } catch {
      self.error = error
      TelemetryDeck.errorOccurred(
        id: "ChatViewModel.updateMessageAction",
        category: .thrownException,
        message: error.localizedDescription
      )
    }
  }
  
  func loadMoreMessages() async {
    await ChatHistoryModifier.shared.loadMoreMessages()
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
      for await cellModels in await ChatHistoryModifier.shared.$cellModels {
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
      for await inProgress in await ChatController.shared.$conversationInProgress {
        await MainActor.run { [weak self] in
          self?.conversationInProgress = inProgress
        }
      }
    }
  }
}
