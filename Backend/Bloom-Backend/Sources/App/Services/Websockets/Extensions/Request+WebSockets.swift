//
//  Request+WebSockets.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-04-01.
//

import Vapor
import WebSocketKit

extension Request {

  var webSocketService: WebSocketService {
    application.webSocketService
  }
}
