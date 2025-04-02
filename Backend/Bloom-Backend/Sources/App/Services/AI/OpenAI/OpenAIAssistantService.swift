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
import Fluent

struct OpenAIAssistantService {
  let openAI: OpenAIKit.Client
  let db: any Database
  let assistantProvider: OpenAIAssistantProvider

  init(
    openAI: OpenAIKit.Client,
    db: any Database,
    assistantProvider: OpenAIAssistantProvider
  ) {
    self.openAI = openAI
    self.db = db
    self.assistantProvider = assistantProvider
  }
}

extension OpenAIAssistantService {

  func createOrFetchAssistantThread(
    user: User,
    assistantSpec: AssistantSpec
  ) async throws-> OpenAIAssistantThread {

    let assistant = try await assistantProvider.createOrUpdateAssistant(
      assistantSpec: assistantSpec
    )

    if let threadID = user[keyPath: assistantSpec.threadIDKeyPath] {
      return OpenAIAssistantThread(
        assistantID: assistant.id,
        threadID: threadID
      )
    }

    return try await createHealthAssistantThread(
      user: user,
      assistant: assistant,
      assistantSpec: assistantSpec
    )
  }

  func cancelCurrentlyActiveRuns(
    assistantThread: OpenAIAssistantThread
  ) async throws {
    let runs = try await openAI.assistants.listRuns(threadID: assistantThread.threadID)

    for run in runs.data {
      if run.status.isActive {
        let run = try await openAI.assistants.cancelRun(
          threadID: assistantThread.threadID,
          runID: run.id
        )

        do {
          let _ = try await openAI.assistants.pollRunForAssistantResponse(
            threadID: assistantThread.threadID,
            runID: run.id
          )
        } catch { } // An error is thrown if the state is cancelled.
      }
    }
  }

  func sendUserContent(
    assistantThread: OpenAIAssistantThread,
    content: [OpenAIKit.Thread.Message.Content]
  ) async throws {
    let _ = try await openAI.assistants.createMessage(
      threadID: assistantThread.threadID,
      message: Thread.Message(
        role: .user,
        content: content
      )
    )
  }

  func reportHealthData(
    assistantThread: OpenAIAssistantThread,
    healthData: String
  ) async throws {
    let _ = try await openAI.assistants.createMessage(
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
    assistantThread: OpenAIAssistantThread,
    message: String
  ) async throws {
    let _ = try await openAI.assistants.createMessage(
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
    assistantThread: OpenAIAssistantThread,
    tools: [Assistant.Tool]? = nil,
    toolChoice: Run.ToolChoice? = nil
  ) async throws -> Run {
    try await openAI.assistants.createRun(
      assistantID: assistantThread.assistantID,
      threadID: assistantThread.threadID,
      tools: tools,
      toolChoice: toolChoice
    )
  }

  func startRunAndPollForResponse(
    assistantThread: OpenAIAssistantThread,
    tools: [Assistant.Tool]? = nil,
    toolChoice: Run.ToolChoice? = nil
  ) async throws -> PollRunResponse {
    let run = try await openAI.assistants.createRun(
      assistantID: assistantThread.assistantID,
      threadID: assistantThread.threadID,
      tools: tools,
      toolChoice: toolChoice
    )
    return try await openAI.assistants.pollRunForAssistantResponse(
      threadID: assistantThread.threadID,
      runID: run.id,
      pollInterval: 1
    )
  }

  @discardableResult
  func submitSuccessfulToolOputput(
    threadID: String,
    runID: String,
    toolCalls: [Run.ToolCall]
  ) async throws -> Run {
    let toolOutputs = toolCalls.map { ToolOutput(toolCallID: $0.id, output: "") }
    return try await openAI.assistants.submitToolOutput(
      threadID: threadID,
      runID: runID,
      toolOutputs: toolOutputs
    )
  }

  func deleteThread(auth: Request.Authentication, assistantSpec: AssistantSpec) async throws {
    guard var user = auth.get(User.self) else {
      throw Abort(.unauthorized, reason: "User authentication required.")
    }

    guard let threadID = user[keyPath: assistantSpec.threadIDKeyPath] else { return }

    let response = try await openAI.assistants.deleteThread(threadID: threadID)

    guard
      response.id == threadID,
      response.object == .threadDeleted,
      response.deleted
    else {
      throw Abort(.internalServerError, reason: "Failed to delete thread.")
    }

    user[keyPath: assistantSpec.threadIDKeyPath] = nil

    try await user.save(on: db)
  }
}

private extension OpenAIAssistantService {

  func createHealthAssistantThread(
    user: User,
    assistant: Assistant,
    assistantSpec: AssistantSpec
  ) async throws -> OpenAIAssistantThread {
    let thread = try await openAI.assistants.createThread(messages: [])

    var user = user
    user[keyPath: assistantSpec.threadIDKeyPath] = thread.id

    try await user.save(on: db)

    return OpenAIAssistantThread(
      assistantID: assistant.id,
      threadID: thread.id
    )
  }
}
