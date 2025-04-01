//
//  WebSocketService.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-03-31.
//

import WebSocketKit

struct WebSocketService {
  let socket: WebSocket

  init(socket: WebSocket) {
    self.socket = socket
    setupSocket()
  }
}

extension WebSocketService {

  func send(_ message: String) {
    socket.send(message)
  }
}

private extension WebSocketService {

  func setupSocket() {
    socket.onText(onText(socket:text:))
    socket.onBinary(onBinary(socket:buffer:))
    socket.onClose.whenComplete(onClose(result:))
  }
}

private extension WebSocketService {

  @Sendable
  func onText(socket: WebSocket, text: String) {

  }

  @Sendable
  func onBinary(socket: WebSocket, buffer: ByteBuffer) {

  }

  @Sendable
  func onClose(result: Result<Void, any Error>) {

  }
}
