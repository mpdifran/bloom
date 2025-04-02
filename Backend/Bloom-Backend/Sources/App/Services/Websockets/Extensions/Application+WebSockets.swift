//
//  Application+WebSockets.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-04-01.
//

import Vapor
import WebSocketKit
import Fluent

extension Application {

  private struct WebSocketServiceKey: StorageKey {
    typealias Value = WebSocketService
  }

  func setupWebSocketService() {
    let service = WebSocketService(
      application: self,
      logger: logger
    )
    storage[WebSocketServiceKey.self] = service
  }

  var webSocketService: WebSocketService {
    guard let service = storage[WebSocketServiceKey.self] else {
      fatalError("WebSocket service not setup")
    }
    return service
  }

  func chatWebSocketService(user: User, socket: WebSocket, db: any Database) -> ChatWebSocketService {
    ChatWebSocketService(
      user: user,
      socket: socket,
      assistantService: openAIAssistantService(db: db)
    )
  }
}
