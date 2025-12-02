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

      // Index for target_audience (filtering by audience)
      try await sqlDatabase.raw("""
        CREATE INDEX CONCURRENTLY IF NOT EXISTS sales_target_audience_index
        ON sales (target_audience);
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
}
