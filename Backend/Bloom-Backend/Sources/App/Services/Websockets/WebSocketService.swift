//
//  WebSocketService.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-03-31.
//

import WebSocketKit

final actor WebSocketService {
  static let shared = WebSocketService()

  var sockets = [String : WebSocket]()

  private init() { }
}

extension WebSocketService {

  func register(socket: WebSocket, for userID: String) {
    sockets[userID] = socket

    socket.onText { (socket, text) in

    }

    socket.onClose.whenComplete { [weak self] (result) in
      Task { await self?.removeSocket(for: userID) }
    }
  }

  func removeSocket(for userID: String) {
    sockets.removeValue(forKey: userID)
  }
}

private extension WebSocketService {

}
