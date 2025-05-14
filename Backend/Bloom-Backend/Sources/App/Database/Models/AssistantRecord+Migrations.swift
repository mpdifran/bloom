//
//  AssistantRecord+Migrations.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-02-14.
//

import Foundation
import Vapor
import Fluent

extension AssistantRecord {
  struct Create: AsyncMigration {
    func prepare(on database: any Database) async throws {
      try await database.schema(AssistantRecord.schema)
        .field(.AssistantRecord.id, .string, .identifier(auto: false))
        .field(.AssistantRecord.name, .string)
        .field(.AssistantRecord.assistantID, .string)
        .field(.AssistantRecord.createdAt, .datetime)
        .field(.AssistantRecord.updatedAt, .datetime)
        .create()
    }

    func revert(on database: any Database) async throws {
      try await database.schema(AssistantRecord.schema).delete()
    }
  }

  struct AddAssistantSpecHash: AsyncMigration {
    func prepare(on database: any Database) async throws {
      try await database.schema(AssistantRecord.schema)
        .field(.AssistantRecord.assistantSpecHash, .string)
        .update()
    }

    func revert(on database: any Database) async throws {
      try await database.schema(AssistantRecord.schema)
        .deleteField(.AssistantRecord.assistantSpecHash)
        .update()
    }
  }
}
