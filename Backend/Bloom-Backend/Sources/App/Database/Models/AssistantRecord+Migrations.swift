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
        .field("id", .string, .identifier(auto: false))
        .field("name", .string)
        .field("assistant_id", .string)
        .field("created_at", .datetime)
        .field("updated_at", .datetime)
        .create()
    }

    func revert(on database: any Database) async throws {
      try await database.schema(AssistantRecord.schema).delete()
    }
  }
}
