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
          $0.post("report-health-data", use: reportHealthData)
          $0.post("new-message", use: newChatMessage)
          $0.post("delete-thread", use: deleteThread)
        }
      }
    }
  }
}

extension ChatController {

  @Sendable
  func reportHealthData(_ request: Request) async throws -> Response {
    let body = try request.content.decode(ChatReportHealthDataRequest.self)

    let assistantThread = try await openAIService.createOrFetchAssistantThread(
      request,
      assistantSpec: .healthCoach
    )

    try await openAIService.reportHealthData(
      request,
      assistantThread: assistantThread,
      healthData: body.healthData
    )

    return Response(status: .ok)
  }

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

    try await openAIService.sendChatMessage(
      request,
      assistantThread: assistantThread,
      message: body.message
    )

    let assistantResponse = try await openAIService.startRunAndPollForResponse(
      request,
      assistantThread: assistantThread
    )

    switch assistantResponse {
    case .requiresAction(_, _):
      throw Abort(.internalServerError, reason: "Unexpected tool call.")
    case .messages(_, let messages):
      let textMessages = messages.flatMap { message in
        message.content.compactMap({ $0.text })
      }
      return ChatMessageResponse(messages: textMessages)
    }
  }

  @Sendable
  func deleteThread(_ request: Request) async throws -> Response {
    try await openAIService.deleteThread(request, assistantSpec: .healthCoach)
    return Response(status: .ok)
  }
}
