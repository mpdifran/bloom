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

    // TODO: Poll current run status, and send typing indicator if Run is active

    let db = createDB(for: socket)
    socket.eventLoop.execute {
      socket.onText { [weak self] (socket, text) in
        Task {
          await self?.handleErrors(socket: socket) { [weak self] in
            guard let data = text.data(using: .utf8) else {
              throw Abort(.preconditionFailed)
            }

            try await self?.onData(
              data: data,
              userID: userID,
              db: db
            )
          }
        }
      }
      socket.onBinary { [weak self] (socket, byteBuffer) in
        Task {
          await self?.handleErrors(socket: socket) { [weak self] in
            let data = Data(buffer: byteBuffer)
            try await self?.onData(
              data: data,
              userID: userID,
              db: db
            )
          }
        }
      }
      socket.onPing { [weak self] (socket, byteBuffer) in
        self?.logger.debug("Received ping on socket for user \(userID)")
        Task {
          do {
            try await socket.sendPing()
          } catch {
            self?.logger.report(error: error)
          }
        }
      }
      socket.onClose.whenComplete { [weak self] (result) in
        switch result {
        case .success(let success):
          break
        case .failure(let failure):
          self?.logger.debug("On Socket close")
          self?.logger.report(error: failure)
        }
        Task {
          await self?.removeSocket(for: userID)
        }
      }
    }
  }

  func webSocket(for userID: UserIdentifier) -> WebSocket? {
    chatSockets[userID]
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
      logger.report(error: error)
      let errorMessage = SocketMessage.Error(errorMessage: error.localizedDescription)
      do {
        try socket.sendContent(errorMessage)
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
    data: Data,
    userID: UserIdentifier,
    db: any Database
  ) async throws {
    if try await application.chatService.parse(data: data, for: userID, db: db) {
      // success
    } else {
      throw Abort(.badRequest)
    }
  }
}
