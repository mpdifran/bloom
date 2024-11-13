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
            let stateEnumType = try await database.enum("state")
                .case("unverified")
                .case("verified")
                .create()

            try await database.schema(FoodItemRecord.schema)
                .id()
                .field("name", .string, .required)
                .field("state", stateEnumType, .required)
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
                .field("serving_name", .string)
                .field("serving_value", .double)
                .field("serving_unit", .string)
                .field("created_at", .datetime)
                .field("updated_at", .datetime)
                .create()
        }

        func revert(on database: any Database) async throws {
            try await database.schema(FoodItemRecord.schema).delete()
            try await database.enum("state").delete()
        }
    }
}
