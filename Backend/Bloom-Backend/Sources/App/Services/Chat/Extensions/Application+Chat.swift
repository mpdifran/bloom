//
//  Application+Chat.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-04-21.
//

import Vapor

extension Application {

  private struct ChatServiceKey: StorageKey {
    typealias Value = ChatService
  }

  var chatService: ChatService {
    if let service = storage[ChatServiceKey.self] {
      return service
    }

    let service = ChatService(
      application: self,
      logger: logger
    )

    storage[ChatServiceKey.self] = service
    return service
  }
}

extension Application {

  private struct ChatHistoryKey: StorageKey {
    typealias Value = ChatHistory
  }

  var chatHistory: ChatHistory {
    if let service = storage[ChatHistoryKey.self] {
      return service
    }

    let service = ChatHistory(
      redis: redis,
      logger: logger
    )

    storage[ChatHistoryKey.self] = service
    return service
  }
}

extension Application {

  private struct ToolCallTrackerKey: StorageKey {
    typealias Value = ToolCallTracker
  }

  var toolCallTracker: ToolCallTracker {
    if let tracker = storage[ToolCallTrackerKey.self] {
      return tracker
    }

    let tracker = ToolCallTracker(maxToolCallsPerRequest: maxChatToolCallsPerMessage)
    storage[ToolCallTrackerKey.self] = tracker
    return tracker
  }
}
