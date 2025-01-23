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

  struct FixUserIDColumnName: AsyncMigration {
    func prepare(on database: any Database) async throws {
      try await database.schema(AdminUserToken.schema)
        .deleteField("user_id")
        .field("admin_user_id", .string, .required, .references(AdminUser.schema, "id"))
        .update()
    }

    func revert(on database: any Database) async throws {
      try await database.schema(AdminUserToken.schema)
        .deleteField("admin_user_id")
        .field("user_id", .string, .required, .references(AdminUser.schema, "id"))
        .update()
    }
  }
}
