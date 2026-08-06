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

private extension WebSocketMaxFrameSize {
  static let frameSize = WebSocketMaxFrameSize(integerLiteral: 1 << 17)
}

struct ChatController { }

extension ChatController: RouteCollection {

  func boot(routes: any RoutesBuilder) throws {
    routes.group("v1") {
      $0.auth(using: UserToken.self) {
        $0.group("chat") {
          $0.webSocket("web-socket", maxFrameSize: .frameSize, onUpgrade: createWebSocket)
          $0.post("submit-tool-call-response", use: submitToolCallResponses)
          $0.post("upload-image", use: uploadImage)
          $0.get("delete-thread", use: deleteThread)
          $0.post("report-issue", use: reportIssue)
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

    let modelOverride = request.openAIModel

    await request.webSocketService.registerChat(
      socket: webSocket,
      forUserID: userID,
      version: .v2,
      modelOverride: modelOverride
    )
  }

  @Sendable
  func submitToolCallResponses(_ request: Request) async throws -> Response {
    let user = try request.auth.require(User.self)

    guard let userID = user.id else { throw Abort(.unauthorized) }
    guard let byteBuffer = request.body.data else { throw Abort(.badRequest, reason: "Request body is missing") }

    let data = Data(buffer: byteBuffer)

    let modelOverride = request.openAIModel
    
    if try await request.chatService.parse(data: data, for: userID, db: request.db, modelOverride: modelOverride) {
      return Response(status: .ok)
    }
    return Response(status: .internalServerError)
  }

  /// Max images accepted in a single chat upload request.
  static let maxImageUploadCount = 10
  /// Max size per uploaded image (bytes).
  static let maxImageUploadBytes = 5 * 1024 * 1024

  @Sendable
  func uploadImage(_ request: Request) async throws -> ChatUploadFileResponse {
    let user = try request.auth.require(User.self)
    guard let userID = user.id else {
      throw Abort(.internalServerError, reason: "User ID unexpectedly nil after authentication.")
    }

    // Each image is uploaded to OpenAI — gate on the user's AI budget so this can't be used to
    // fan out unbounded, un-metered uploads.
    try await request.aiUsageLimiter.checkBudget(for: userID)

    let body = try request.content.decode(ChatUploadFileRequest.self)

    guard !body.images.isEmpty else {
      throw Abort(.badRequest, reason: "No images provided.")
    }
    guard body.images.count <= Self.maxImageUploadCount else {
      throw Abort(.badRequest, reason: "Too many images. Please upload at most \(Self.maxImageUploadCount) at a time.")
    }
    guard body.images.allSatisfy({ $0.count <= Self.maxImageUploadBytes }) else {
      throw Abort(.badRequest, reason: "One or more images exceed the size limit.")
    }

    let fileIDs = try await request.chatService.uploadImages(imageData: body.images)
    return ChatUploadFileResponse(fileIDs: fileIDs)
  }

  @Sendable
  func deleteThread(_ request: Request) async throws -> Response {
    let user = try request.auth.require(User.self)

    guard let userID = user.id else {
      throw Abort(.internalServerError, reason: "User ID unexpectedly nil after authentication.")
    }

    try await request.chatHistory.clearFunctionCallIDs(for: userID)
    try await request.chatHistory.clearLastResponseID(for: userID)
    try await request.chatHistory.clearStreamingContent(userID: userID)

    return Response(status: .ok)
  }
  
  @Sendable
  func reportIssue(_ request: Request) async throws -> Response {
    let user = try request.auth.require(User.self)
    let requestBody = try request.content.decode(SubmitChatMessageIssueRequest.self)
    
    let issueReport = ChatMessageIssueReport(
      responseID: requestBody.responseID,
      notes: requestBody.notes,
      appVersion: requestBody.appVersion,
      userID: requestBody.isAnonymous ? nil : user.id
    )
    
    try await issueReport.save(on: request.db)
    
    return Response(status: .ok)
  }
}
