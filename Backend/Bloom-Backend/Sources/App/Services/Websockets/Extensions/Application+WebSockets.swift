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

  var webSocketService: WebSocketService {
    if let existing = storage[WebSocketServiceKey.self] {
      return existing
    }

    let webSocketService = WebSocketService(
      application: self,
      logger: logger
    )
    storage[WebSocketServiceKey.self] = webSocketService

    return webSocketService
  }
}
