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

  @ID(custom: .AssistantRecord.id, generatedBy: .user)
  var id: String?

  @Field(key: .AssistantRecord.name)
  var name: String

  @Field(key: .AssistantRecord.assistantID)
  var assistantID: String

  @Field(key: .AssistantRecord.assistantSpecHash)
  var assistantSpecHash: String?

  @Timestamp(key: .AssistantRecord.createdAt, on: .create)
  var createdAt: Date?

  @Timestamp(key: .AssistantRecord.updatedAt, on: .update)
  var updatedAt: Date?

  init() { }

  init(
    id: String,
    name: String,
    assistantID: String,
    assistantSpecHash: String
  ) {
    self.id = id
    self.name = name
    self.assistantID = assistantID
    self.assistantSpecHash = assistantSpecHash
  }
}

extension FieldKey {
  enum AssistantRecord {
    static let id = FieldKey("id")
    static let name = FieldKey("name")
    static let assistantID = FieldKey("assistant_id")
    static let assistantSpecHash = FieldKey("assistant_spec_hash")
    static let createdAt = FieldKey("created_at")
    static let updatedAt = FieldKey("updated_at")
  }
}
