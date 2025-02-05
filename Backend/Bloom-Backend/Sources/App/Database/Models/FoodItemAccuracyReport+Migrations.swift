//
//  FoodItemAccuracyReport+Migrations.swift
//  Bloom-Backend
//
//  Created by Haocen Jiang on 2025-02-03.
//

import Foundation
import Vapor
import Fluent
import SQLKit

extension FoodItemAccuracyReport {
  struct Create: AsyncMigration {
    func prepare(on database: Database) async throws {
      try await database.schema(FoodItemAccuracyReport.schema)
        .field("id", .string, .identifier(auto: false))
        .field(
          "food_item_record_id",
          .string,
          .required,
          .references(FoodItemRecord.schema, "id", onDelete: .cascade)
        )
        .field("accuracy_score", .double, .required)
        .field("evaluation_notes", .string)
        .field("recommendations", .json)
        .field("created_at", .datetime, .required)
        .create()
      
      guard let sqlDatabase = database as? SQLDatabase else {
        // Skip creating the index
        return
      }
      
      try await sqlDatabase
        .create(index: "idx_food_item_record_id_created_at")
        .on(FoodItemAccuracyReport.schema)
        .column("food_item_record_id")
        .column("created_at")
        .run()
    }
    
    func revert(on database: Database) async throws {
      try await database.schema(FoodItemAccuracyReport.schema).delete()
    }
  }
}
