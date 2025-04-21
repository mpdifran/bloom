//
//  Application+Chat.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-04-21.
//

import Vapor
import WebSocketKit
import Fluent

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
