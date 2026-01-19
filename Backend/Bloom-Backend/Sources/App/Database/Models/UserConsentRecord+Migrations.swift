//
//  UserConsentRecord+Migrations.swift
//  Bloom-Backend
//
//  Created by Claude on 2025-01-29.
//

import Foundation
import Vapor
import Fluent
import SQLKit
import BloomModel

extension UserConsentRecord {
  struct Create: AsyncMigration {
    func prepare(on database: any Database) async throws {
      try await database.schema(UserConsentRecord.schema)
        .id()
        .field("user_id", .string, .required, .references(User.schema, "id"))
        .field("created_at", .datetime)
        .field("health_data_consent_screen_version", .string)
        .field("external_health_data_screen_version", .string)
        .field("health_data_consent", .bool)
        .field("chat_with_bud_consent", .bool)
        .field("today_insights_consent", .bool)
        .field("biological_age_consent", .bool)
        .field("physical_activity_consent", .bool)
        .field("body_metrics_consent", .bool)
        .field("mental_wellness_consent", .bool)
        .field("sleep_consent", .bool)
        .field("nutrition_consent", .bool)
        .field("digestive_health_consent", .bool)
        .field("menstrual_health_consent", .bool)
        .field("demographics_consent", .bool)
        .field("goals_consent", .bool)
        .field("location_consent", .bool)
        .field("weather_consent", .bool)
        .field("calendar_events_consent", .bool)
        .create()
    }

    func revert(on database: any Database) async throws {
      try await database.schema(UserConsentRecord.schema).delete()
    }
  }

  struct AddUserIDIndex: AsyncMigration {
    func prepare(on database: any Database) async throws {
      guard let sqlDatabase = database as? SQLDatabase else {
        return
      }

      try await sqlDatabase
        .create(index: "idx_user_consent_records_user_id")
        .on(UserConsentRecord.schema)
        .column("user_id")
        .run()
    }

    func revert(on database: any Database) async throws {
      guard let sqlDatabase = database as? SQLDatabase else {
        return
      }

      try await sqlDatabase
        .drop(index: "idx_user_consent_records_user_id")
        .run()
    }
  }

  struct MigrateExistingConsent: AsyncMigration {
    func prepare(on database: any Database) async throws {
      guard let sqlDatabase = database as? SQLDatabase else {
        return
      }

      // Query users with consent data using raw SQL
      let rows = try await sqlDatabase.raw("""
        SELECT id, health_data_consent_granted_at, external_processing_consent_granted_at
        FROM users
        WHERE health_data_consent_granted_at IS NOT NULL
           OR external_processing_consent_granted_at IS NOT NULL
        """)
        .all()

      for row in rows {
        guard let userID = try? row.decode(column: "id", as: String.self) else {
          continue
        }

        let healthDataConsentAt = try? row.decode(column: "health_data_consent_granted_at", as: Date.self)
        let externalProcessingConsentAt = try? row.decode(column: "external_processing_consent_granted_at", as: Date.self)

        // Determine the timestamp for the record
        let createdAt: Date
        if let healthDate = healthDataConsentAt, let externalDate = externalProcessingConsentAt {
          createdAt = min(healthDate, externalDate)
        } else {
          createdAt = healthDataConsentAt ?? externalProcessingConsentAt ?? Date()
        }

        // Create the consent record
        let record = UserConsentRecord(
          userID: UserIdentifier(userID),
          healthDataConsent: healthDataConsentAt != nil ? true : nil,
          chatWithBudConsent: externalProcessingConsentAt != nil ? true : nil,
          todayInsightsConsent: externalProcessingConsentAt != nil ? true : nil,
          biologicalAgeConsent: externalProcessingConsentAt != nil ? true : nil
        )

        // Manually set created_at to the historical timestamp
        record.createdAt = createdAt

        try await record.save(on: database)
      }
    }

    func revert(on database: any Database) async throws {
      // Delete all migrated consent records
      try await UserConsentRecord.query(on: database).delete()
    }
  }

  struct AddMonitorConsent: AsyncMigration {
    func prepare(on database: any Database) async throws {
      try await database.schema(UserConsentRecord.schema)
        .field("monitor_consent", .bool)
        .update()
    }

    func revert(on database: any Database) async throws {
      try await database.schema(UserConsentRecord.schema)
        .deleteField("monitor_consent")
        .update()
    }
  }
}

extension User {
  struct RemoveOldConsentFields: AsyncMigration {
    func prepare(on database: any Database) async throws {
      try await database.schema(User.schema)
        .deleteField("health_data_consent_granted_at")
        .deleteField("external_processing_consent_granted_at")
        .update()
    }

    func revert(on database: any Database) async throws {
      try await database.schema(User.schema)
        .field("health_data_consent_granted_at", .datetime)
        .field("external_processing_consent_granted_at", .datetime)
        .update()
    }
  }
}
