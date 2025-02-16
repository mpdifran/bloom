//
//  AssistantRecord.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-02-14.
//

import Foundation
import Vapor
import Fluent
import BloomModel

final class AssistantRecord: Model, Content, @unchecked Sendable {
  static let schema = "assistants"

  @ID(custom: "id", generatedBy: .user)
  var id: String?

  @Field(key: "name")
  var name: String

  @Field(key: "assistant_id")
  var assistantID: String

  @Timestamp(key: "created_at", on: .create)
  var createdAt: Date?

  @Timestamp(key: "updated_at", on: .update)
  var updatedAt: Date?

  init() { }

  init(
    id: String,
    name: String,
    assistantID: String
  ) {
    self.id = id
    self.name = name
    self.assistantID = assistantID
  }
}
