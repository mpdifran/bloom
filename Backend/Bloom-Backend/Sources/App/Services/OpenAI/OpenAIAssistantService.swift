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

  func cancelCurrentlyActiveRuns(
    _ request: Request,
    assistantThread: OpenAIAssistantThread
  ) async throws {
    let runs = try await request.openAI.assistants.listRuns(threadID: assistantThread.threadID)

    for run in runs.data {
      if run.status.isActive {
        let run = try await request.openAI.assistants.cancelRun(
          threadID: assistantThread.threadID,
          runID: run.id
        )

        do {
          let _ = try await request.openAI.assistants.pollRunForAssistantResponse(
            threadID: assistantThread.threadID,
            runID: run.id
          )
        } catch { } // An error is thrown if the state is cancelled.
      }
    }
  }

  func sendUserContent(
    _ request: Request,
    assistantThread: OpenAIAssistantThread,
    content: [OpenAIKit.Thread.Message.Content]
  ) async throws {
    let _ = try await request.openAI.assistants.createMessage(
      threadID: assistantThread.threadID,
      message: Thread.Message(
        role: .user,
        content: content
      )
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

  func createRun(
    _ request: Request,
    assistantThread: OpenAIAssistantThread,
    tools: [Assistant.Tool]? = nil,
    toolChoice: Run.ToolChoice? = nil
  ) async throws -> Run {
    try await request.openAI.assistants.createRun(
      assistantID: assistantThread.assistantID,
      threadID: assistantThread.threadID,
      tools: tools,
      toolChoice: toolChoice
    )
  }

  func startRunAndPollForResponse(
    _ request: Request,
    assistantThread: OpenAIAssistantThread,
    tools: [Assistant.Tool]? = nil,
    toolChoice: Run.ToolChoice? = nil
  ) async throws -> PollRunResponse {
    let run = try await request.openAI.assistants.createRun(
      assistantID: assistantThread.assistantID,
      threadID: assistantThread.threadID,
      tools: tools,
      toolChoice: toolChoice
    )
    return try await request.openAI.assistants.pollRunForAssistantResponse(
      threadID: assistantThread.threadID,
      runID: run.id,
      pollInterval: 1
    )
  }

  @discardableResult
  func submitSuccessfulToolOputput(
    _ request: Request,
    threadID: String,
    runID: String,
    toolCalls: [Run.ToolCall]
  ) async throws -> Run {
    let toolOutputs = toolCalls.map { ToolOutput(toolCallID: $0.id, output: "") }
    return try await request.openAI.assistants.submitToolOutput(
      threadID: threadID,
      runID: runID,
      toolOutputs: toolOutputs
    )
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
