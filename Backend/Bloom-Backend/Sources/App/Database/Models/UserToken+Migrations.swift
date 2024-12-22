//
//  UserToken+Migrations.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-12-22.
//

import Foundation
import Vapor
import Fluent

extension UserToken {
  struct Create: AsyncMigration {
    func prepare(on database: any Database) async throws {
      try await database.schema(UserToken.schema)
        .id()
        .field("value", .string, .required)
        .field("user_id", .string, .required, .references(User.schema, "id"))
        .unique(on: "value")
        .create()
    }

    func revert(on database: any Database) async throws {
      try await database.schema(UserToken.schema).delete()
    }
  }
}
