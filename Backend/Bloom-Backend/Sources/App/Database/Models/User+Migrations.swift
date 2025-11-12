//
//  User+Migrations.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-12-22.
//

import Foundation
import Vapor
import Fluent

extension User {
  struct Create: AsyncMigration {
    func prepare(on database: any Database) async throws {
      try await database.schema(User.schema)
        .field("id", .string, .identifier(auto: false))
        .field("access_token", .string)
        .field("refresh_token", .string)
        .field("id_token", .string)
        .field("access_token_expiry", .datetime)
        .field("created_at", .datetime)
        .field("updated_at", .datetime)
        .create()
    }

    func revert(on database: any Database) async throws {
      try await database.schema(User.schema).delete()
    }
  }

  struct AddUserDetails: AsyncMigration {
    func prepare(on database: any Database) async throws {
      try await database.schema(User.schema)
        .field("email", .string)
        .field("given_name", .string)
        .field("family_name", .string)
        .field("user_detection_status", .string)
        .update()
    }

    func revert(on database: any Database) async throws {
      try await database.schema(User.schema)
        .deleteField("email")
        .deleteField("given_name")
        .deleteField("family_name")
        .deleteField("user_detection_status")
        .update()
    }
  }

  struct AddAppUserID: AsyncMigration {
    func prepare(on database: any Database) async throws {
      try await database.schema(User.schema)
        .field("app_user_id", .string)
        .update()
    }

    func revert(on database: any Database) async throws {
      try await database.schema(User.schema)
        .deleteField("app_user_id")
        .update()
    }
  }

  struct AddAssistantAndThreadIDs: AsyncMigration {
    func prepare(on database: any Database) async throws {
      try await database.schema(User.schema)
        .field("assistant_id", .string)
        .field("thread_id", .string)
        .update()
    }

    func revert(on database: any Database) async throws {
      try await database.schema(User.schema)
        .deleteField("assistant_id")
        .deleteField("thread_id")
        .update()
    }
  }

  struct RemoveAssistantID: AsyncMigration {
    func prepare(on database: any Database) async throws {
      try await database.schema(User.schema)
        .deleteField("assistant_id")
        .update()
    }

    func revert(on database: any Database) async throws {
      try await database.schema(User.schema)
        .field("assistant_id", .string)
        .update()
    }
  }

  struct RenameThreadID: AsyncMigration {
    func prepare(on database: any Database) async throws {
      try await database.schema(User.schema)
        .deleteField("thread_id")
        .field("health_coach_thread_id", .string)
        .update()
    }

    func revert(on database: any Database) async throws {
      try await database.schema(User.schema)
        .deleteField("health_coach_thread_id")
        .field("thread_id", .string)
        .update()
    }
  }

  struct AddHealthGoalSetterThreadID: AsyncMigration {
    func prepare(on database: any Database) async throws {
      try await database.schema(User.schema)
        .field("health_goal_setter_thread_id", .string)
        .update()
    }

    func revert(on database: any Database) async throws {
      try await database.schema(User.schema)
        .deleteField("health_goal_setter_thread_id")
        .update()
    }
  }

  struct AddAppVersion: AsyncMigration {
    func prepare(on database: any Database) async throws {
      try await database.schema(User.schema)
        .field("app_version", .string)
        .update()
    }

    func revert(on database: any Database) async throws {
      try await database.schema(User.schema)
        .deleteField("app_version")
        .update()
    }
  }

  struct AddAPNSDeviceToken: AsyncMigration {
    func prepare(on database: any Database) async throws {
      try await database.schema(User.schema)
        .field("apns_device_token", .string)
        .update()
    }
    
    func revert(on database: any Database) async throws {
      try await database.schema(User.schema)
        .deleteField("apns_device_token")
        .update()
    }
  }

  struct AddMorningNotificationTime: AsyncMigration {
    func prepare(on database: any Database) async throws {
      try await database.schema(User.schema)
        .field("morning_notification_hour", .int)
        .field("morning_notification_minute", .int)
        .update()
    }

    func revert(on database: any Database) async throws {
      try await database.schema(User.schema)
        .deleteField("morning_notification_hour")
        .deleteField("morning_notification_minute")
        .update()
    }
  }

  struct AddConsentTracking: AsyncMigration {
    func prepare(on database: any Database) async throws {
      try await database.schema(User.schema)
        .field("health_data_consent_granted_at", .datetime)
        .field("external_processing_consent_granted_at", .datetime)
        .update()
    }

    func revert(on database: any Database) async throws {
      try await database.schema(User.schema)
        .deleteField("health_data_consent_granted_at")
        .deleteField("external_processing_consent_granted_at")
        .update()
    }
  }
}
