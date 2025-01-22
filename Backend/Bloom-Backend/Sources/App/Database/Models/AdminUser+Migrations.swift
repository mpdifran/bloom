//
//  AdminUser+Migrations.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-01-22.
//

import Foundation
import Vapor
import Fluent

extension AdminUser {
  struct Create: AsyncMigration {
    func prepare(on database: any Database) async throws {
      try await database.schema(AdminUser.schema)
        .field("id", .string, .identifier(auto: false))
        .field("email", .string)
        .field("given_name", .string)
        .field("family_name", .string)
        .field("user_detection_status", .string)
        .field("access_token", .string)
        .field("refresh_token", .string)
        .field("id_token", .string)
        .field("access_token_expiry", .datetime)
        .field("created_at", .datetime)
        .field("updated_at", .datetime)
        .create()
    }

    func revert(on database: any Database) async throws {
      try await database.schema(AdminUser.schema).delete()
    }
  }
}
