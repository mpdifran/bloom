//
//  FoodItemIssueReport+Migrations.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-01-27.
//

import Foundation
import Vapor
import Fluent

extension FoodItemIssueReport {
  struct Create: AsyncMigration {

    func prepare(on database: any Database) async throws {
      try await database.schema(FoodItemIssueReport.schema)
        .field("id", .string, .identifier(auto: false))
        .field("name", .string, .required)
        .field("brand_name", .string)
        .field("flavour", .string)
        .field("barcode", .string)
        .field("nutrition_label_image", .string)
        .field("packaging_image", .string)
        .field("ingredients", .string)
        .field("calories", .double)
        .field("protein", .double)
        .field("carbohydrates", .double)
        .field("fat", .double)
        .field("saturated_fat", .double)
        .field("trans_fat", .double)
        .field("polyunsaturated_fat", .double)
        .field("monounsaturated_fat", .double)
        .field("fiber", .double)
        .field("sugar", .double)
        .field("cholesterol", .double)
        .field("sodium", .double)
        .field("calcium", .double)
        .field("iron", .double)
        .field("potassium", .double)
        .field("magnesium", .double)
        .field("zinc", .double)
        .field("vitamin_a", .double)
        .field("vitamin_b6", .double)
        .field("vitamin_b12", .double)
        .field("vitamin_c", .double)
        .field("vitamin_d", .double)
        .field("vitamin_e", .double)
        .field("serving_name", .string)
        .field("serving_value", .double)
        .field("serving_unit", .string)
        .field("created_at", .datetime)
        .field("updated_at", .datetime)
        .field("notes", .string)
        .field("user_id", .string, .required, .references(User.schema, "id"))
        .create()
    }

    func revert(on database: any Database) async throws {
      try await database.schema(FoodItemIssueReport.schema).delete()
    }
  }

  struct FixRelations: AsyncMigration {

    func prepare(on database: any Database) async throws {
      try await database.schema(FoodItemIssueReport.schema)
        .deleteField("user_id")
        .field("user_id", .string, .references(User.schema, "id"))
        .field("food_item_record_id", .string, .required, .references(FoodItemRecord.schema, "id"))
        .update()
    }

    func revert(on database: any Database) async throws {
      try await database.schema(FoodItemIssueReport.schema)
        .deleteField("user_id")
        .field("user_id", .string, .required, .references(User.schema, "id"))
        .deleteField("food_item_record_id")
        .update()
    }
  }

  struct MakeNameOptional: AsyncMigration {

    func prepare(on database: any Database) async throws {
      try await database.schema(FoodItemIssueReport.schema)
        .deleteField("name")
        .field("name", .string)
        .update()
    }

    func revert(on database: any Database) async throws {
      try await database.schema(FoodItemIssueReport.schema)
        .deleteField("name")
        .field("name", .string, .required)
        .update()
    }
  }

  struct RemoveBarcodePropoerty: AsyncMigration {

    func prepare(on database: any Database) async throws {
      try await database.schema(FoodItemIssueReport.schema)
        .deleteField("barcode")
        .update()
    }

    func revert(on database: any Database) async throws {
      try await database.schema(FoodItemIssueReport.schema)
        .field("barcode", .string)
        .update()
    }
  }
}
