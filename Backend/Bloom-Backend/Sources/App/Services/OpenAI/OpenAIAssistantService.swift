//
//  OpenAIAssistantService.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-02-12.
//

import BloomModel
import Foundation
import Logging
import OpenAIKit
import Vapor

struct OpenAIAssistantService {
  private let assistantProvider = OpenAIAssistantProvider()
}

extension OpenAIAssistantService {

  func createOrFetchAssistantThread(
    _ request: Request,
    assistantSpec: AssistantSpec
  ) async throws-> OpenAIAssistantThread {

    guard let user = request.auth.get(User.self) else {
      throw Abort(.unauthorized, reason: "User authentication required.")
    }

    let assistant = try await assistantProvider.createOrUpdateAssistant(
      request,
      assistantSpec: assistantSpec
    )

    if let threadID = user[keyPath: assistantSpec.threadIDKeyPath] {
      return OpenAIAssistantThread(
        assistantID: assistant.id,
        threadID: threadID
      )
    }

    return try await createHealthAssistantThread(
      request,
      assistant: assistant,
      assistantSpec: assistantSpec
    )
  }

  func reportHealthData(
    _ request: Request,
    assistantThread: OpenAIAssistantThread,
    healthData: String
  ) async throws {
    let _ = try await request.openAI.assistants.createMessage(
      threadID: assistantThread.threadID,
      message: Thread.Message(
        role: .user,
        content: [
          .text("Here is my latest health data.\n\n```\n\(healthData)\n```")
        ]
      )
    )
  }

  func sendChatMessage(
    _ request: Request,
    assistantThread: OpenAIAssistantThread,
    message: String
  ) async throws {
    let _ = try await request.openAI.assistants.createMessage(
      threadID: assistantThread.threadID,
      message: Thread.Message(
        role: .user,
        content: [
          .text(message)
        ]
      )
    )
  }

  func startRunAndPollForResponse(
    _ request: Request,
    assistantThread: OpenAIAssistantThread
  ) async throws -> [Message] {
    let run = try await request.openAI.assistants.createRun(
      assistantID: assistantThread.assistantID,
      threadID: assistantThread.threadID
    )
    let (_, messages) = try await request.openAI.assistants.pollRunForAssistantResponse(
      threadID: assistantThread.threadID,
      runID: run.id,
      pollInterval: 0.5
    )

    guard messages.isNotEmpty else {
      throw Abort(.internalServerError)
    }

    return messages
  }

  func deleteThread(_ request: Request, assistantSpec: AssistantSpec) async throws {
    guard var user = request.auth.get(User.self) else {
      throw Abort(.unauthorized, reason: "User authentication required.")
    }

    guard let threadID = user[keyPath: assistantSpec.threadIDKeyPath] else { return }

    let response = try await request.openAI.assistants.deleteThread(threadID: threadID)

    guard
      response.id == threadID,
      response.object == .threadDeleted,
      response.deleted
    else {
      throw Abort(.internalServerError, reason: "Failed to delete thread.")
    }

    user[keyPath: assistantSpec.threadIDKeyPath] = nil

    try await user.save(on: request.db)
  }
}

private extension OpenAIAssistantService {

  func createHealthAssistantThread(
    _ request: Request,
    assistant: Assistant,
    assistantSpec: AssistantSpec
  ) async throws -> OpenAIAssistantThread {
    guard var user = request.auth.get(User.self) else {
      throw Abort(.unauthorized, reason: "User authentication required.")
    }

    let thread = try await request.openAI.assistants.createThread(messages: [])

    user[keyPath: assistantSpec.threadIDKeyPath] = thread.id

    try await user.save(on: request.db)

    return OpenAIAssistantThread(
      assistantID: assistant.id,
      threadID: thread.id
    )
  }
}
