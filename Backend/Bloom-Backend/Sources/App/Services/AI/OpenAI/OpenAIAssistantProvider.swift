//
//  OpenAIAssistantProvider.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-02-15.
//

import Foundation
import Vapor
import Fluent
import Logging
import BloomModel
import OpenAIKit

struct OpenAIAssistantProvider { }

extension OpenAIAssistantProvider {

  func createOrUpdateAssistant(
    _ request: Request,
    assistantSpec: AssistantSpec
  ) async throws -> Assistant {

    let assistantID: String
    if let existingAssistant = try await fetchAssisantRecord(request, assistantSpec: assistantSpec) {
      assistantID = existingAssistant.assistantID
    } else {
      let assistant = try await createAsssistant(request, assistantSpec: assistantSpec)
      assistantID = assistant.id
    }

    return try await updateAssistantDetails(
      request,
      assistantID: assistantID,
      assistantSpec: assistantSpec
    )
  }
}

private extension OpenAIAssistantProvider {

  func fetchAssisantRecord(_ request: Request, assistantSpec: AssistantSpec) async throws -> AssistantRecord? {
    try await AssistantRecord
      .query(on: request.db)
      .filter(\.$id == assistantSpec.id)
      .first()
  }

  func createAsssistant(_ request: Request, assistantSpec: AssistantSpec) async throws -> Assistant {
    let assistant = try await request.openAI.assistants.createAssistant(
      model: assistantSpec.model,
      name: assistantSpec.name,
      instructions: assistantSpec.instructions,
      temperature: assistantSpec.temperature
    )

    try await persistAssistant(request, assistant: assistant, assistantSpec: assistantSpec)

    return assistant
  }

  func updateAssistantDetails(
    _ request: Request,
    assistantID: String,
    assistantSpec: AssistantSpec
  ) async throws -> Assistant {
    let assistant = try await request.openAI.assistants.retrieveAssistant(assistantID: assistantID)

    guard
      assistant.name == assistantSpec.name,
      assistant.instructions == assistantSpec.instructions,
      assistant.model == assistantSpec.model.id,
      assistant.temperature == assistantSpec.temperature,
      assistant.topP == assistantSpec.topP,
      assistant.tools == assistantSpec.tools
    else {
      request.logger.info("Updating Assistant \(assistantSpec.id)")
      let updatedAssistant = try await request.openAI.assistants.modifyAssistant(
        assistantID: assistantID,
        model: assistantSpec.model,
        name: assistantSpec.name,
        instructions: assistantSpec.instructions,
        tools: assistantSpec.tools,
        temperature: assistantSpec.temperature,
        topP: assistantSpec.topP
      )

      try await persistAssistant(
        request,
        assistant: updatedAssistant,
        assistantSpec: assistantSpec
      )

      return updatedAssistant
    }

    return assistant
  }

  func persistAssistant(
    _ request: Request,
    assistant: Assistant,
    assistantSpec: AssistantSpec
  ) async throws {
    let assistantRecord: AssistantRecord
    if let existingAssistantRecord = try await fetchAssisantRecord(request, assistantSpec: assistantSpec) {
      existingAssistantRecord.assistantID = assistant.id
      existingAssistantRecord.name = assistantSpec.name

      assistantRecord = existingAssistantRecord
    } else {
      assistantRecord = AssistantRecord(
        id: assistantSpec.id,
        name: assistantSpec.name,
        assistantID: assistant.id
      )
    }
    try await assistantRecord.save(on: request.db)
  }
}
