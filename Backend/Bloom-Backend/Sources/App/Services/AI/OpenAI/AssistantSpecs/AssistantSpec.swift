//
//  AssistantSpec.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-02-15.
//

import Foundation
@preconcurrency import OpenAIKit

extension AssistantSpec {
  static let assistantName = "Bud"
}

struct AssistantSpec: Sendable {
  let id: String
  let name: String
  let model: ModelID
  let temperature: Double?
  let topP: Double?
  let threadIDKeyPath: WritableKeyPath<User, String?>
  let instructions: String
  let tools: [Assistant.Tool]
  let responseFormat: ResponseFormat?

  init(
    id: String,
    name: String,
    model: ModelID,
    temperature: Double? = nil,
    topP: Double? = nil,
    threadIDKeyPath: WritableKeyPath<User, String?>,
    instructions: String,
    tools: [Assistant.Tool],
    responseFormat: ResponseFormat? = nil
  ) {
    self.id = id
    self.name = name
    self.model = model
    self.temperature = temperature
    self.topP = topP
    self.threadIDKeyPath = threadIDKeyPath
    self.instructions = instructions
    self.tools = tools
    self.responseFormat = responseFormat
  }
}
