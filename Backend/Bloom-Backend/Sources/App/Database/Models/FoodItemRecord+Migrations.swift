//
//  FoodItemRecord+Migrations.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-11.
//

import Foundation
import Vapor
import Fluent
import SQLKit

extension FoodItemRecord {
  struct Create: AsyncMigration {
    func prepare(on database: Database) async throws {
      let stateEnumType = try await database.enum(State.self)
        .case(.unverified)
        .case(.verified)
        .create()

      let categoryEnumType = try await database.enum(Category.self)
        .case(.generic)
        .case(.fastfood)
        .case(.restaurant)
        .case(.branded)
        .create()

      let countryEnumType = try await database.enum(Country.self)
        .case(.canada)
        .case(.usa)
        .create()

      try await database.schema(FoodItemRecord.schema)
        .field("id", .string, .identifier(auto: false))
        .field("name", .string, .required)
        .field("state", stateEnumType, .required)
        .field("brand_name", .string)
        .field("flavour", .string)
        .field("category", categoryEnumType, .required)
        .field("barcode", .string)
        .field("nutrition_label_image", .string)
        .field("packaging_image", .string)
        .field("ingredients", .string)
        .field("country", countryEnumType, .required)
        .field("calories", .double)
        .field("protein", .double)
        .field("carbohydrates", .double)
        .field("fat", .double)
        .field("serving_name", .string)
        .field("serving_value", .double)
        .field("serving_unit", .string)
        .field("downvote_count", .int)
        .field("created_at", .datetime)
        .field("updated_at", .datetime)
        .create()

      // Create a trigram index for faster searches
      guard let sqlDatabase = database as? SQLDatabase else {
        fatalError("This migration requires an SQL database.")
      }
      // Trigram index for fuzzy matching on 'name'
      try await sqlDatabase.raw("""
                CREATE INDEX CONCURRENTLY IF NOT EXISTS trgm_name_index
                ON food_item_records
                USING gin (name gin_trgm_ops);
            """).run()

      // Trigram index for fuzzy matching on 'brand_name'
      try await sqlDatabase.raw("""
                CREATE INDEX CONCURRENTLY IF NOT EXISTS trgm_brand_name_index
                ON food_item_records
                USING gin (brand_name gin_trgm_ops);
            """).run()

      // Trigram index for fuzzy matching on 'flavour'
      try await sqlDatabase.raw("""
                CREATE INDEX CONCURRENTLY IF NOT EXISTS trgm_flavour_index
                ON food_item_records
                USING gin (flavour gin_trgm_ops);
            """).run()

      // B-tree index for 'barcode' (exact lookup)
      try await sqlDatabase.raw("""
                CREATE INDEX CONCURRENTLY IF NOT EXISTS barcode_index
                ON food_item_records (barcode);
            """).run()

      // B-tree index for 'category' (equality filtering)
      try await sqlDatabase.raw("""
                CREATE INDEX CONCURRENTLY IF NOT EXISTS category_index
                ON food_item_records (category);
            """).run()

      // B-tree index for 'country' (equality filtering)
      try await sqlDatabase.raw("""
                CREATE INDEX CONCURRENTLY IF NOT EXISTS country_index
                ON food_item_records (country);
            """).run()
    }

    func revert(on database: any Database) async throws {
      try await database.schema(FoodItemRecord.schema).delete()
      try await database.enum(State.self).delete()
      try await database.enum(Country.self).delete()
      try await database.enum(Category.self).delete()
    }
  }

  struct AddNutrients: AsyncMigration {

    func prepare(on database: any Database) async throws {
      try await database.schema(FoodItemRecord.schema)
        .field("fiber", .string)
        .field("sugar", .string)
        .field("saturated_fat", .string)
        .field("trans_fat", .string)
        .field("polyunsaturated_fat", .string)
        .field("monounsaturated_fat", .string)
        .field("cholesterol", .string)
        .field("sodium", .string)
        .field("calcium", .string)
        .field("iron", .string)
        .field("potassium", .string)
        .field("magnesium", .string)
        .field("zinc", .string)
        .field("vitamin_a", .string)
        .field("vitamin_b6", .string)
        .field("vitamin_b12", .string)
        .field("vitamin_c", .string)
        .field("vitamin_d", .string)
        .field("vitamin_e", .string)
        .update()
    }

    func revert(on database: any Database) async throws {
      try await database.schema(FoodItemRecord.schema)
        .deleteField("fiber")
        .deleteField("sugar")
        .deleteField("saturated_fat")
        .deleteField("trans_fat")
        .deleteField("polyunsaturated_fat")
        .deleteField("monounsaturated_fat")
        .deleteField("cholesterol")
        .deleteField("sodium")
        .deleteField("calcium")
        .deleteField("iron")
        .deleteField("potassium")
        .deleteField("magnesium")
        .deleteField("zinc")
        .deleteField("vitamin_a")
        .deleteField("vitamin_b6")
        .deleteField("vitamin_b12")
        .deleteField("vitamin_c")
        .deleteField("vitamin_d")
        .deleteField("vitamin_e")
        .update()
    }
  }

  struct FixNutritionFieldTypes: AsyncMigration {
    func prepare(on database: any Database) async throws {
      let badMigration = AddNutrients()
      try await badMigration.revert(on: database)

      try await database.schema(FoodItemRecord.schema)
        .field("fiber", .double)
        .field("sugar", .double)
        .field("saturated_fat", .double)
        .field("trans_fat", .double)
        .field("polyunsaturated_fat", .double)
        .field("monounsaturated_fat", .double)
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
        .update()
    }

    func revert(on database: any Database) async throws {
      try await database.schema(FoodItemRecord.schema)
        .deleteField("fiber")
        .deleteField("sugar")
        .deleteField("saturated_fat")
        .deleteField("trans_fat")
        .deleteField("polyunsaturated_fat")
        .deleteField("monounsaturated_fat")
        .deleteField("cholesterol")
        .deleteField("sodium")
        .deleteField("calcium")
        .deleteField("iron")
        .deleteField("potassium")
        .deleteField("magnesium")
        .deleteField("zinc")
        .deleteField("vitamin_a")
        .deleteField("vitamin_b6")
        .deleteField("vitamin_b12")
        .deleteField("vitamin_c")
        .deleteField("vitamin_d")
        .deleteField("vitamin_e")
        .update()
    }
  }

  struct AddSourceProperty: AsyncMigration {

    func prepare(on database: any Database) async throws {
      try await database.schema(FoodItemRecord.schema)
        .field("source", .string)
        .update()
    }

    func revert(on database: any Database) async throws {
      try await database.schema(FoodItemRecord.schema)
        .deleteField("source")
        .update()
    }
  }

  struct AddNeedsAIProcessingState: AsyncMigration {
    func prepare(on database: any Database) async throws {
      _ = try await database.enum(State.self)
        .case(.needsAIProcessing)
        .update()
    }

    func revert(on database: any Database) async throws {
      _ = try await database.enum(State.self)
        .deleteCase(.needsAIProcessing)
        .update()
    }
  }

  struct AddNeedsMoreInfoAndNotes: AsyncMigration {
    func prepare(on database: any Database) async throws {
      _ = try await database.enum(State.self)
        .case(.needsMoreInfo)
        .update()

      try await database.schema(FoodItemRecord.schema)
        .field("notes", .string)
        .update()
    }

    func revert(on database: any Database) async throws {
      _ = try await database.enum(State.self)
        .deleteCase(.needsMoreInfo)
        .update()

      try await database.schema(FoodItemRecord.schema)
        .deleteField("notes")
        .update()
    }
  }
}
