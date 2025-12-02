//
//  SaleRecord+Migrations.swift
//  Bloom-Backend
//
//  Created by Claude on 2025-12-02.
//

import Foundation
import Vapor
import Fluent
import SQLKit

extension SaleRecord {
  struct Create: AsyncMigration {
    func prepare(on database: Database) async throws {
      let targetAudienceEnumType = try await database.enum(TargetAudienceEnum.self)
        .case(.allUsers)
        .case(.freeUsers)
        .case(.subscribedUsers)
        .case(.expiredUsers)
        .create()

      try await database.schema(SaleRecord.schema)
        .field("id", .string, .identifier(auto: false))
        .field("title", .string, .required)
        .field("body_text", .string, .required)
        .field("image_url", .string)
        .field("sale_product_id", .string, .required)
        .field("compare_product_id", .string)
        .field("target_audience", targetAudienceEnumType, .required)
        .field("start_date", .datetime, .required)
        .field("end_date", .datetime, .required)
        .field("display_frequency_days", .int, .required)
        .field("is_active", .bool, .required)
        .field("telemetry_event_name", .string, .required)
        .field("created_at", .datetime)
        .field("updated_at", .datetime)
        .create()

      // Create indexes for commonly queried fields
      guard let sqlDatabase = database as? SQLDatabase else {
        fatalError("This migration requires an SQL database.")
      }

      // Index for is_active (filtering active sales)
      try await sqlDatabase.raw("""
        CREATE INDEX CONCURRENTLY IF NOT EXISTS sales_is_active_index
        ON sales (is_active);
      """).run()

      // Index for date range queries
      try await sqlDatabase.raw("""
        CREATE INDEX CONCURRENTLY IF NOT EXISTS sales_date_range_index
        ON sales (start_date, end_date);
      """).run()

      // Composite index for common query pattern (active sales within date range)
      try await sqlDatabase.raw("""
        CREATE INDEX CONCURRENTLY IF NOT EXISTS sales_active_date_index
        ON sales (is_active, start_date, end_date);
      """).run()
    }

    func revert(on database: Database) async throws {
      try await database.schema(SaleRecord.schema).delete()
      try await database.enum(TargetAudienceEnum.self).delete()
    }
  }

  struct UpdateTargetAudiences: AsyncMigration {
    func prepare(on database: Database) async throws {
      // Drop the old single target_audience column
      try await database.schema(SaleRecord.schema)
        .deleteField("target_audience")
        .update()

      // Add the new target_audiences array column
      let targetAudienceEnumType = try await database.enum(TargetAudienceEnum.self).read()

      try await database.schema(SaleRecord.schema)
        .field("target_audiences", .array(of: targetAudienceEnumType), .required)
        .update()

      // Update the index to use GIN for array queries
      guard let sqlDatabase = database as? SQLDatabase else {
        fatalError("This migration requires an SQL database.")
      }

      // Index for target_audiences array (filtering by audience containment)
      try await sqlDatabase.raw("""
        CREATE INDEX CONCURRENTLY IF NOT EXISTS sales_target_audiences_index
        ON sales USING GIN (target_audiences);
      """).run()
    }

    func revert(on database: Database) async throws {
      guard let sqlDatabase = database as? SQLDatabase else {
        fatalError("This migration requires an SQL database.")
      }

      // Drop the array index
      try await sqlDatabase.raw("""
        DROP INDEX IF EXISTS sales_target_audiences_index;
      """).run()

      // Drop the target_audiences array column
      try await database.schema(SaleRecord.schema)
        .deleteField("target_audiences")
        .update()

      // Re-add the single target_audience column
      let targetAudienceEnumType = try await database.enum(TargetAudienceEnum.self).read()

      try await database.schema(SaleRecord.schema)
        .field("target_audience", targetAudienceEnumType, .required)
        .update()
    }
  }
}
