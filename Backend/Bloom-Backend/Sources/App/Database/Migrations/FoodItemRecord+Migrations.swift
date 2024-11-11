//
//  FoodItemRecord+Migrations.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-11.
//

import Foundation
import Vapor
import Fluent

extension FoodItemRecord {
    struct Create: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(FoodItemRecord.schema)
                .id()
                .field("name", .string, .required)
                .field("brand_name", .string)
                .field("barcode", .string)
                .field("nutrition_label_image", .string)
                .field("packaging_image", .string)
                .field("ingredients", .string)
                .field("calories", .double)
                .field("protein", .double)
                .field("carbohydrates", .double)
                .field("fat", .double)
                .field("servings", .string)
                .field("created_at", .datetime)
                .field("updated_at", .datetime)
                .create()
        }

        func revert(on database: any Database) async throws {
            try await database.schema(FoodItemRecord.schema).delete()
        }
    }
}
