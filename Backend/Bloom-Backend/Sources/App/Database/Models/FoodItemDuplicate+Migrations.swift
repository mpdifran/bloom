//
//  FoodItemDuplicate+Migrations.swift
//  Bloom-Backend
//
//  Created by Assistant on 2025-09-09.
//

import Foundation
import Vapor
import Fluent

extension FoodItemDuplicate {
  struct Create: AsyncMigration {
    func prepare(on database: Database) async throws {
      let adminStatusEnum = try await database.enum(AdminStatus.self)
        .case(.pending)
        .case(.markedDistinct)
        .create()

      try await database.schema(FoodItemDuplicate.schema)
        .id()
        .field("food_item_id", .string, .required, .references(FoodItemRecord.schema, "id", onDelete: .cascade))
        .field("duplicate_food_item_id", .string, .required, .references(FoodItemRecord.schema, "id", onDelete: .cascade))
        .field("similarity_score", .double, .required)
        .field("match_types", .string, .required)
        .field("admin_status", adminStatusEnum, .required)
        .field("admin_user_id", .string)
        .field("admin_decision_at", .datetime)
        .field("created_at", .datetime)
        .field("updated_at", .datetime)
        .unique(on: "food_item_id", "duplicate_food_item_id")
        .create()
    }

    func revert(on database: Database) async throws {
      try await database.schema(FoodItemDuplicate.schema).delete()
      try await database.enum(AdminStatus.self).delete()
    }
  }
}