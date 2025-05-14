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

struct OpenAIAssistantProvider {
  let db: any Database
  let openAI: OpenAIKit.Client
  let logger: Logger
}

extension OpenAIAssistantProvider {

  /// - returns: The Assistant ID.
  func createOrUpdateAssistant(
    assistantSpec: AssistantSpec
  ) async throws -> String {
    let assistantID: String
    if let existingAssistant = try await fetchAssisantRecord(assistantSpec: assistantSpec) {
      assistantID = existingAssistant.assistantID
    } else {
      let assistant = try await createAsssistant(assistantSpec: assistantSpec)
      assistantID = assistant.id
    }

    try await updateAssistantDetails(
      assistantID: assistantID,
      assistantSpec: assistantSpec
    )

    return assistantID
  }
}

private extension OpenAIAssistantProvider {

  func fetchAssisantRecord(assistantSpec: AssistantSpec) async throws -> AssistantRecord? {
    try await AssistantRecord
      .query(on: db)
      .filter(\.$id == assistantSpec.id)
      .first()
  }

  func createAsssistant(assistantSpec: AssistantSpec) async throws -> Assistant {
    let assistant = try await openAI.assistants.createAssistant(
      model: assistantSpec.model,
      name: assistantSpec.name,
      instructions: assistantSpec.instructions,
      tools: assistantSpec.tools,
      temperature: assistantSpec.temperature,
      topP: assistantSpec.topP,
      responseFormat: assistantSpec.responseFormat
    )

    try await persistAssistant(assistant: assistant, assistantSpec: assistantSpec)

    return assistant
  }

  func updateAssistantDetails(
    assistantID: String,
    assistantSpec: AssistantSpec
  ) async throws {
    let assistantSpecHash = "\(assistantSpec.hashValue)"
    if let existingAssistantRecord = try await fetchAssisantRecord(assistantSpec: assistantSpec) {
      if existingAssistantRecord.assistantSpecHash == assistantSpecHash {
        return
      }
    }

    logger.info("Updating Assistant \(assistantSpec.id)")

    let updatedAssistant = try await openAI.assistants.modifyAssistant(
      assistantID: assistantID,
      model: assistantSpec.model,
      name: assistantSpec.name,
      instructions: assistantSpec.instructions,
      tools: assistantSpec.tools,
      temperature: assistantSpec.temperature,
      topP: assistantSpec.topP,
      responseFormat: assistantSpec.responseFormat
    )

    try await persistAssistant(
      assistant: updatedAssistant,
      assistantSpec: assistantSpec
    )
  }

  func persistAssistant(
    assistant: Assistant,
    assistantSpec: AssistantSpec
  ) async throws {
    let assistantRecord: AssistantRecord
    if let existingAssistantRecord = try await fetchAssisantRecord(assistantSpec: assistantSpec) {
      existingAssistantRecord.assistantID = assistant.id
      existingAssistantRecord.name = assistantSpec.name
      existingAssistantRecord.assistantSpecHash = "\(assistantSpec.hashValue)"

      assistantRecord = existingAssistantRecord
    } else {
      assistantRecord = AssistantRecord(
        id: assistantSpec.id,
        name: assistantSpec.name,
        assistantID: assistant.id,
        assistantSpecHash: "\(assistantSpec.hashValue)"
      )
    }
    try await assistantRecord.save(on: db)
  }
}
