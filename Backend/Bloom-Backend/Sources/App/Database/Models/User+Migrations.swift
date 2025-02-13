//
//  User+Migrations.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-12-22.
//

import Foundation
import Vapor
import Fluent

extension User {
  struct Create: AsyncMigration {
    func prepare(on database: any Database) async throws {
      try await database.schema(User.schema)
        .field("id", .string, .identifier(auto: false))
        .field("access_token", .string)
        .field("refresh_token", .string)
        .field("id_token", .string)
        .field("access_token_expiry", .datetime)
        .field("created_at", .datetime)
        .field("updated_at", .datetime)
        .create()
    }

    func revert(on database: any Database) async throws {
      try await database.schema(User.schema).delete()
    }
  }

  struct AddUserDetails: AsyncMigration {
    func prepare(on database: any Database) async throws {
      try await database.schema(User.schema)
        .field("email", .string)
        .field("given_name", .string)
        .field("family_name", .string)
        .field("user_detection_status", .string)
        .update()
    }

    func revert(on database: any Database) async throws {
      try await database.schema(User.schema)
        .deleteField("email")
        .deleteField("given_name")
        .deleteField("family_name")
        .deleteField("user_detection_status")
        .update()
    }
  }

  struct AddAppUserID: AsyncMigration {
    func prepare(on database: any Database) async throws {
      try await database.schema(User.schema)
        .field("app_user_id", .string)
        .update()
    }

    func revert(on database: any Database) async throws {
      try await database.schema(User.schema)
        .deleteField("app_user_id")
        .update()
    }
  }

  struct AddAssistantAndThreadIDs: AsyncMigration {
    func prepare(on database: any Database) async throws {
      try await database.schema(User.schema)
        .field("assistant_id", .string)
        .field("thread_id", .string)
        .update()
    }

    func revert(on database: any Database) async throws {
      try await database.schema(User.schema)
        .deleteField("assistant_id")
        .deleteField("thread_id")
        .update()
    }
  }
}
