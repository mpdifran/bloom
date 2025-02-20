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
  let temperature: Double
  let threadIDKeyPath: WritableKeyPath<User, String?>
  let instructions: String
  let tools: [Assistant.Tool]
}
