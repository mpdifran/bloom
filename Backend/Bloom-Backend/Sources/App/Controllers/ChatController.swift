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
          // Documents are base64-encoded in a JSON body, so allow for the ~4/3 overhead on top of
          // the combined size limit.
          $0.on(.POST, "upload-document", body: .collect(maxSize: "64mb"), use: uploadDocument)
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

  /// Max documents accepted in a single chat upload request.
  static let maxDocumentUploadCount = 10

  @Sendable
  func uploadDocument(_ request: Request) async throws -> ChatUploadFileResponse {
    let user = try request.auth.require(User.self)
    guard let userID = user.id else {
      throw Abort(.internalServerError, reason: "User ID unexpectedly nil after authentication.")
    }

    // Same as images: each document is uploaded to OpenAI, so gate on the user's AI budget.
    try await request.aiUsageLimiter.checkBudget(for: userID)

    let body = try request.content.decode(ChatUploadDocumentRequest.self)

    guard !body.documents.isEmpty else {
      throw Abort(.badRequest, reason: "No documents provided.")
    }
    guard body.documents.count <= Self.maxDocumentUploadCount else {
      throw Abort(.badRequest, reason: "Too many files. Please upload at most \(Self.maxDocumentUploadCount) at a time.")
    }
    if let unsupported = body.documents.first(where: { !ChatUploadDocumentRequest.isSupported(filename: $0.filename) }) {
      throw Abort(.unsupportedMediaType, reason: "\(unsupported.filename) isn't a supported file type.")
    }
    guard body.documents.allSatisfy({ $0.data.count <= ChatUploadDocumentRequest.maxDocumentBytes }) else {
      throw Abort(.payloadTooLarge, reason: "One or more files exceed the size limit.")
    }
    guard body.documents.reduce(0, { $0 + $1.data.count }) <= ChatUploadDocumentRequest.maxTotalBytes else {
      throw Abort(.payloadTooLarge, reason: "These files are too large to send together.")
    }

    let fileIDs = try await request.chatService.uploadDocuments(body.documents)
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
