//
//  ChatController.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-02-12.
//

import Foundation
import Vapor
import BloomModel
import WebSocketKit

struct ChatController { }

extension ChatController: RouteCollection {

  func boot(routes: any RoutesBuilder) throws {
    routes.group("v1") {
      $0.auth(using: UserToken.self) {
        $0.group("chat") {
          $0.webSocket("create-web-socket", shouldUpgrade: prepareForWebSocket, onUpgrade: createWebSocket)
          $0.post("delete-thread", use: deleteThread)
        }
      }
    }
  }
}

extension ChatController {

  @Sendable
  func prepareForWebSocket(_ request: Request) async throws -> HTTPHeaders? {
    let user = try request.auth.require(User.self)
    guard let userID = user.id else { throw Abort(.forbidden) }

    return HTTPHeaders([("UserID", userID.value)])
  }

  @Sendable
  func createWebSocket(_ request: Request, webSocket: WebSocket) async {
    guard let userIDRaw = request.headers["UserID"].first else {
      request.logger.warning("UserID header not found or malformed.")
      return
    }

    let userID = UserIdentifier(userIDRaw)
    await request.webSocketService.registerChat(
      socket: webSocket,
      forUserID: userID
    )
  }

  @Sendable
  func deleteThread(_ request: Request) async throws -> Response {
    try await request.openAIAssistantService.deleteThread(
      auth: request.auth,
      assistantSpec: .healthCoach
    )
    return Response(status: .ok)
  }
}
