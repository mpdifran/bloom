//
//  AdminUserToken+Migrations.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-01-22.
//

import Foundation
import Vapor
import Fluent

extension AdminUserToken {
  struct Create: AsyncMigration {
    func prepare(on database: any Database) async throws {
      try await database.schema(AdminUserToken.schema)
        .id()
        .field("value", .string, .required)
        .field("user_id", .string, .required, .references(AdminUser.schema, "id"))
        .unique(on: "value")
        .create()
    }

    func revert(on database: any Database) async throws {
      try await database.schema(AdminUserToken.schema).delete()
    }
  }
}
