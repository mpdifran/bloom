//
//  ChatWebSocketService.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-04-01.
//

import Vapor
import WebSocketKit
import BloomModel

struct ChatWebSocketService: Sendable {
  let user: User
  let socket: WebSocket
  let assistantService: OpenAIAssistantService

  init(
    user: User,
    socket: WebSocket,
    assistantService: OpenAIAssistantService
  ) {
    self.user = user
    self.socket = socket
    self.assistantService = assistantService
  }

  private let decoder = JSONDecoder.bloomModel
}

extension ChatWebSocketService {

  func parse(data: Data) async throws -> Bool {
    if let message = try? decoder.decode(WebSocketMessage.Message.self, from: data) {
      try await on(message: message)
    } else {
      return false
    }
    return true
  }

  func on(message: WebSocketMessage.Message) async throws {
    let thread = try await assistantService.createOrFetchAssistantThread(
      user: user,
      assistantSpec: .healthCoach
    )

    try await assistantService.sendChatMessage(
      assistantThread: thread,
      message: message.text
    )

    try await performRun(thread: thread)
  }
}

private extension ChatWebSocketService {

  func performRun(thread: OpenAIAssistantThread) async throws {
    let assistantResponse = try await assistantService.startRunAndPollForResponse(assistantThread: thread)

    switch assistantResponse {
    case .requiresAction(_, let tools):
      // Handle tool call
      break
    case .messages(_, let messages):
      let textMessages = messages.flatMap { message in
        message.content.compactMap({ $0.text })
      }
      // Send to client
    }
  }
}
