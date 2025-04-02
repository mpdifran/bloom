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

  private let application: Application
  private let logger: Logger!

  init(
    application: Application,
    logger: Logger
  ) {
    self.application = application
    self.logger = logger
  }

  private var chatSockets = [UserIdentifier : WebSocket]() {
    didSet {
      logger.debug("WebSocketService - \(chatSockets.count) active sockets")
    }
  }
}

extension WebSocketService {

  func registerChat(socket: WebSocket, forUserID userID: UserIdentifier) {
    chatSockets[userID] = socket

    let db = createDB(for: socket)

    socket.onText { [weak self] (socket, text) in
      Task {
        await self?.handleErrors(socket: socket) { [weak self] in
          guard let data = text.data(using: .utf8) else {
            throw Abort(.preconditionFailed)
          }

          try await self?.onData(
            socket: socket,
            db: db,
            data: data,
            userID: userID
          )
        }
      }
    }
    socket.onBinary { [weak self] (socket, byteBuffer) in
      Task {
        await self?.handleErrors(socket: socket) { [weak self] in
          let data = Data(buffer: byteBuffer)
          try await self?.onData(
            socket: socket,
            db: db,
            data: data,
            userID: userID
          )
        }
      }
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

  func handleErrors(socket: WebSocket, _ block: @escaping () async throws -> Void) async {
    do {
      try await block()
    } catch {
      let errorMessage = WebSocketMessage.Error(message: error.localizedDescription)
      do {
        try socket.send(errorMessage)
      } catch {
        logger.report(error: error)
      }
    }
  }

  func createDB(for socket: WebSocket) -> any Database {
    // This is based on how Request creates its db.
    application.databases.database(
      nil,
      logger: Logger(label: "com.lotus-labs.web-socket.db"),
      on: socket.eventLoop,
      history: nil, // TODO: Do we need this enabled?
      pageSizeLimit: application.fluent.pagination.pageSizeLimit
    )!
  }

  func onData(
    socket: WebSocket,
    db: any Database,
    data: Data,
    userID: UserIdentifier
  ) async throws {
    let userDatabaseService = application.userDatabaseService(db: db)

    guard let user = try await userDatabaseService.fetchUser(for: userID) else {
      throw Abort(.forbidden)
    }

    let chatWebSocketService = application.chatWebSocketService(
      user: user,
      socket: socket,
      db: db
    )

    if try await chatWebSocketService.parse(data: data) {
      // success
    } else {
      throw Abort(.badRequest)
    }
  }
}

