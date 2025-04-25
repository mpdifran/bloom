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
  var assistantTypingStatus: String?
  var assistantIsTyping = false
  var scrollToLatestMessageToggle = false
  var error: Error?

  init() {
    setupObservers()
  }

  private var typingStatusTask: Task<Void, Never>?
  private var isTypingTask: Task<Void, Never>?
  private var scrollToLatestMessageTask: Task<Void, Never>?
  private var errorTask: Task<Void, Never>?

  private let modelContext = ContainerHolder.shared.createContext()
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
    try modelContext.deleteAll(ChatMessage.self)
  }
}

private extension ChatViewModel {

  func setupObservers() {
    typingStatusTask = Task.detached { [weak self] in
      for await assistantTypingStatus in await ChatController.shared.$assistantTypingStatus {
        await MainActor.run { [weak self] in
          self?.assistantTypingStatus = assistantTypingStatus
        }
      }
    }
    isTypingTask = Task.detached { [weak self] in
      for await isTyping in await ChatController.shared.$assistantIsTyping {
        await MainActor.run { [weak self] in
          self?.assistantIsTyping = isTyping
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
    scrollToLatestMessageTask = Task.detached { [weak self] in
      for await scrollToLatestMessageToggle in await ChatController.shared.$scrollToLatestMessageToggle {
        await MainActor.run { [weak self] in
          self?.scrollToLatestMessageToggle = scrollToLatestMessageToggle
        }
      }
    }
  }
}
