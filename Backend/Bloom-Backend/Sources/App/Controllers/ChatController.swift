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
          $0.webSocket("web-socket", onUpgrade: createWebSocket)
          $0.post("upload-image", use: uploadImage)
          $0.get("delete-thread", use: deleteThread)
        }
      }
    }
  }
}

extension ChatController {

  @Sendable
  func createWebSocket(_ request: Request, webSocket: WebSocket) async {
    guard
      let user = try? request.auth.require(User.self),
      let userID = user.id
    else {
      request.logger.warning("No authorized user found.")
      return
    }

    await request.webSocketService.registerChat(
      socket: webSocket,
      forUserID: userID
    )
  }

  @Sendable
  func uploadImage(_ request: Request) async throws -> ChatUploadFileResponse {
    let body = try request.content.decode(ChatUploadFileRequest.self)

    let fileIDs = try await withThrowingTaskGroup(of: String.self) { group in
      for image in body.images {
        group.addTask {
          let file = try await request.openAIAssistantService.uploadFile(data: image)
          return file.id
        }
      }

      var fileIDs = [String]()
      for try await fileID in group {
        fileIDs.append(fileID)
      }
      return fileIDs
    }

    return ChatUploadFileResponse(fileIDs: fileIDs)
  }

  @Sendable
  func deleteThread(_ request: Request) async throws -> Response {
    let user = try request.auth.require(User.self)

    try await request.openAIAssistantService.deleteThread(
      user: user,
      assistantSpec: .healthCoach
    )
    return Response(status: .ok)
  }
}
