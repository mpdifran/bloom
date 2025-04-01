//
//  WebSocketService.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-03-31.
//

import Vapor
import FluentKit
import WebSocketKit
import BloomModel

final actor WebSocketService {
  static let shared = WebSocketService()

  var db: (any Database)!
  var chatSockets = [UserIdentifier : WebSocket]()

  private init() { }
}

extension WebSocketService {

  func link(to database: any Database) {
    self.db = database
  }

  func registerChat(socket: WebSocket, forUserID userID: UserIdentifier) {
    chatSockets[userID] = socket

    socket.onText { [weak self] (socket, text) in
      Task { await self?.onText(socket: socket, text: text, userID: userID) }
    }

    socket.onClose.whenComplete { [weak self] (result) in
      Task { await self?.removeSocket(for: userID) }
    }
  }

  func removeSocket(for userID: UserIdentifier) {
    chatSockets.removeValue(forKey: userID)
  }
}

private extension WebSocketService {

  func onText(socket: WebSocket, text: String, userID: UserIdentifier) {
    // parse the JSON
    // Pull the user from the DB
    // Call a delegate with the data
  }
}
