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

@Observable @MainActor
final class ChatViewModel {
  var cellModels = [ChatCellModel]()
  var error: Error?

  init() {
    setupObservers()
  }

  private var cellModelsTask: Task<Void, Never>?
  private var errorTask: Task<Void, Never>?
}

extension ChatViewModel {

  func sendMessage(_ message: String, image: UIImage?) async {
    do {
      try await ChatController.shared.send(message: message, image: image)
    } catch {
      self.error = error
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
        }
      }
    }
  }
}
