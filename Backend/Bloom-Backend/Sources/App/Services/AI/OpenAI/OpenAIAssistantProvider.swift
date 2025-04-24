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

  func createOrUpdateAssistant(
    assistantSpec: AssistantSpec
  ) async throws -> Assistant {

    let assistantID: String
    if let existingAssistant = try await fetchAssisantRecord(assistantSpec: assistantSpec) {
      assistantID = existingAssistant.assistantID
    } else {
      let assistant = try await createAsssistant(assistantSpec: assistantSpec)
      assistantID = assistant.id
    }

    return try await updateAssistantDetails(
      assistantID: assistantID,
      assistantSpec: assistantSpec
    )
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
  ) async throws -> Assistant {
    let assistant = try await openAI.assistants.retrieveAssistant(assistantID: assistantID)

    guard
      assistant.model == assistantSpec.model.id,
      assistant.name == assistantSpec.name,
      assistant.instructions == assistantSpec.instructions,
      assistant.tools == assistantSpec.tools,
      (assistant.temperature == assistantSpec.temperature || assistantSpec.temperature == nil),
      (assistant.topP == assistantSpec.topP || assistantSpec.topP == nil),
      (assistant.responseFormat == assistantSpec.responseFormat) || assistantSpec.responseFormat == nil
    else {
      logger.info("Updating Assistant \(assistantSpec.id)")

      if assistant.model != assistantSpec.model.id {
        logger.info("Changing assistant model from \(assistant.model) to \(assistantSpec.model.id).")
      }
      if assistant.name != assistantSpec.name {
        logger.info("Changing assistant name from \(assistant.name ?? "") to \(assistantSpec.name).")
      }
      if assistant.instructions != assistantSpec.instructions {
        logger.info("Changing assistant instructions from \(assistant.instructions ?? "") to \(assistantSpec.instructions).")
      }
      if assistant.tools != assistantSpec.tools {
        logger.info("Changing assistant tools from \(assistant.tools) to \(assistantSpec.tools).")
      }
      if assistant.temperature != assistantSpec.temperature && assistantSpec.temperature != nil {
        logger.info("Changing assistant temperature from \(String(describing: assistant.temperature)) to \(String(describing: assistantSpec.temperature)).")
      }
      if assistant.topP != assistantSpec.topP && assistantSpec.topP != nil {
        logger.info("Changing assistant topP from \(String(describing: assistant.topP)) to \(String(describing: assistantSpec.topP)).")
      }
      if assistant.responseFormat != assistantSpec.responseFormat && assistantSpec.responseFormat != nil {
        logger.info("Changing assistant response format from \(String(describing: assistant.responseFormat)) to \(String(describing: assistantSpec.responseFormat)).")
      }

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

      return updatedAssistant
    }

    return assistant
  }

  func persistAssistant(
    assistant: Assistant,
    assistantSpec: AssistantSpec
  ) async throws {
    let assistantRecord: AssistantRecord
    if let existingAssistantRecord = try await fetchAssisantRecord(assistantSpec: assistantSpec) {
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
    try await assistantRecord.save(on: db)
  }
}
