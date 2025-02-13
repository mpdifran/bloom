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

struct OpenAIAssistantService { }

extension OpenAIAssistantService {

  func createOrFetchAssistantThread(_ request: Request) async throws-> OpenAIAssistantThread {

    guard let user = request.auth.get(User.self) else {
      throw Abort(.unauthorized, reason: "User authentication required.")
    }

    if let assistantID = user.assistantID, let threadID = user.threadID {
      return OpenAIAssistantThread(
        assistantID: assistantID,
        threadID: threadID
      )
    }

    return try await createHealthAssistantThread(request, user: user)
  }

  func reportHealthData(
    _ request: Request,
    assistantThread: OpenAIAssistantThread,
    healthData: ChatHealthData
  ) async throws {
    let rawData = try JSONEncoder.bloomModel.encode(healthData)

    guard let stringHealthData = String(data: rawData, encoding: .utf8) else {
      throw Abort(.internalServerError)
    }

    let _ = try await request.openAI.assistants.createMessage(
      threadID: assistantThread.threadID,
      message: Thread.Message(
        role: .user,
        content: [
          .text("Here is my latest health data in JSON format."),
          .text("```\n\(stringHealthData)\n```")
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
  ) async throws -> Message {
    let run = try await request.openAI.assistants.createRun(
      assistantID: assistantThread.assistantID,
      threadID: assistantThread.threadID
    )
    let message = try await request.openAI.assistants.pollRunForAssistantResponse(
      threadID: assistantThread.threadID,
      runID: run.id,
      pollInterval: 0.5
    )

    guard let message else {
      throw Abort(.internalServerError)
    }

    return message
  }
}

private extension OpenAIAssistantService {

  func createHealthAssistantThread(_ request: Request, user: User) async throws -> OpenAIAssistantThread {
    let assistant = try await request.openAI.assistants.createAssistant(
      model: Model.GPT4.gpt4Turbo,
      name: "Bud",
      instructions: """
        Your name is Bud. When responding, you may introduce yourself as Bud.

        You are a health advisor, helping users analyze and understand their health data. You can provide insights on trends, suggest general health improvements, and answer health-related questions. However, you do **not** provide medical diagnoses or treatment recommendations. If the user needs medical advice, encourage them to consult a healthcare professional.

        The user will provide health data to you in JSON format. 
        - Only reference this health data **if the user asks about it or if it’s directly relevant** to their question.
        - If relevant, you may **gently remind** the user that you have data available to analyze.

        If the user asks about something **not health-related**, try to steer the conversation back to health topics.

        When giving responses, make sure to be **concise**! You cna dive into details when the user asks clarifying questions. You may ask follow-up questions if more context would improve your answer.
        """
    )

    let thread = try await request.openAI.assistants.createThread(messages: [])

    user.assistantID = assistant.id
    user.threadID = thread.id

    try await user.save(on: request.db)

    return OpenAIAssistantThread(assistantID: assistant.id, threadID: thread.id)
  }
}
