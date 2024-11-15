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
            let stateEnumType = try await database.enum("state")
                .case("unverified")
                .case("verified")
                .create()

            let categoryEnumType = try await database.enum("category")
                .case("generic")
                .case("fastfood")
                .case("restaurant")
                .case("branded")
                .create()

            let countryEnumType = try await database.enum("country")
                .case("canada")
                .case("usa")
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
            try await database.enum("state").delete()
            try await database.enum("country").delete()
            try await database.enum("category").delete()
        }
    }
}
