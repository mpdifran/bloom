//
//  Request+Chat.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-04-22.
//

import Vapor

extension Request {

  var chatService: ChatService {
    application.chatService
  }
}
