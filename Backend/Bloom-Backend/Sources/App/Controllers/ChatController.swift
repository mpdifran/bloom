//
//  ChatController.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-02-12.
//

import Foundation
import Vapor
import BloomModel

struct ChatController {
  private let openAIService = OpenAIAssistantService()
}

extension ChatController: RouteCollection {

  func boot(routes: any RoutesBuilder) throws {
    routes.group("v1") {
      $0.auth(using: UserToken.self) {
        $0.group("chat") {
          $0.post("new-message", use: newChatMessage)
          $0.get("delete-thread", use: deleteThread)
        }
      }
    }
  }
}

extension ChatController {

  @Sendable
  func newChatMessage(_ request: Request) async throws -> ChatMessageResponse {
    let body = try request.content.decode(ChatMessageRequest.self)

    let assistantThread = try await openAIService.createOrFetchAssistantThread(
      request,
      assistantSpec: .healthCoach
    )

    if let healthData = body.healthData {
      try await openAIService.reportHealthData(
        request,
        assistantThread: assistantThread,
        healthData: healthData
      )
    }

    if let message = body.message {
      try await openAIService.sendChatMessage(
        request,
        assistantThread: assistantThread,
        message: message
      )
    }

    let assistantResponse = try await openAIService.startRunAndPollForResponse(request, assistantThread: assistantThread)
    let messages = assistantResponse.content.compactMap({ $0.text })

    return ChatMessageResponse(messages: messages)
  }

  @Sendable
  func deleteThread(_ request: Request) async throws -> Response {
    try await openAIService.deleteThread(request)

    return Response(status: .ok)
  }
}
