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
  private let openAI: OpenAIKit.Client
  private let db: any Database
  private let assistantProvider: OpenAIAssistantProvider
  private let userDatabaseService: UserDatabaseService

  init(
    openAI: OpenAIKit.Client,
    db: any Database,
    assistantProvider: OpenAIAssistantProvider
  ) {
    self.openAI = openAI
    self.db = db
    self.assistantProvider = assistantProvider
    self.userDatabaseService = UserDatabaseService(db: db)
  }
}

extension OpenAIAssistantService {

  func createOrFetchAssistantThread(
    userID: UserIdentifier,
    assistantSpec: AssistantSpec
  ) async throws -> OpenAIAssistantThread? {
    guard let user = try await userDatabaseService.fetchUser(for: userID) else {
      return nil
    }
    return try await createOrFetchAssistantThread(user: user, assistantSpec: assistantSpec)
  }

  func createOrFetchAssistantThread(
    user: User,
    assistantSpec: AssistantSpec
  ) async throws -> OpenAIAssistantThread {

    let assistantID = try await assistantProvider.createOrUpdateAssistant(
      assistantSpec: assistantSpec
    )

    if let threadID = user[keyPath: assistantSpec.threadIDKeyPath] {
      return OpenAIAssistantThread(
        assistantID: assistantID,
        threadID: threadID
      )
    }

    return try await createHealthAssistantThread(
      user: user,
      assistantID: assistantID,
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
    try await sendChatMessage(assistantThread: assistantThread, messages: [message])
  }

  func sendChatMessage(
    assistantThread: OpenAIAssistantThread,
    messages: [String]
  ) async throws {
    let _ = try await openAI.assistants.createMessage(
      threadID: assistantThread.threadID,
      message: Thread.Message(
        role: .user,
        content: messages.map { .text($0) }
      )
    )
  }

  func sendChatContent(
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

  func streamRun(
    assistantThread: OpenAIAssistantThread,
    tools: [Assistant.Tool]? = nil,
    toolChoice: Run.ToolChoice? = nil
  ) async throws -> AsyncThrowingStream<ThreadStreamEvent, Error> {
    try await openAI.assistants.createAndStreamRun(
      assistantID: assistantThread.assistantID,
      threadID: assistantThread.threadID,
      tools: tools,
      toolChoice: toolChoice
    )
  }

  func startRunAndPollForResponse(
    assistantThread: OpenAIAssistantThread,
    tools: [Assistant.Tool]? = nil,
    toolChoice: Run.ToolChoice? = nil,
    existingRun: Run? = nil
  ) async throws -> PollRunResponse {
    if let existingRun {
      return try await openAI.assistants.pollRunForAssistantResponse(
        threadID: assistantThread.threadID,
        runID: existingRun.id,
        pollInterval: 1
      )
    }

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

  func submitSuccessfulToolOputput(
    threadID: String,
    runID: String,
    toolOutputs: [ToolOutput]
  ) async throws -> Run {
    return try await openAI.assistants.submitToolOutput(
      threadID: threadID,
      runID: runID,
      toolOutputs: toolOutputs
    )
  }

  func submitSuccessfulToolOputputAndStreamRun(
    threadID: String,
    runID: String,
    toolOutputs: [ToolOutput]
  ) async throws -> AsyncThrowingStream<ThreadStreamEvent, Error> {
    return try await openAI.assistants.submitToolOutputAndStreamRun(
      threadID: threadID,
      runID: runID,
      toolOutputs: toolOutputs
    )
  }

  func deleteThread(user: User, assistantSpec: AssistantSpec) async throws {
    var user = user

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

extension OpenAIAssistantService {

  func uploadFile(data: Data) async throws -> OpenAIKit.File {
    try await openAI.files.upload(
      file: data,
      fileName: "\(UUID().uuidString).png",
      purpose: .assistants
    )
  }
}

private extension OpenAIAssistantService {

  func createHealthAssistantThread(
    user: User,
    assistantID: String,
    assistantSpec: AssistantSpec
  ) async throws -> OpenAIAssistantThread {
    let thread = try await openAI.assistants.createThread(messages: [])

    var user = user
    user[keyPath: assistantSpec.threadIDKeyPath] = thread.id

    try await user.save(on: db)

    return OpenAIAssistantThread(
      assistantID: assistantID,
      threadID: thread.id
    )
  }
}
