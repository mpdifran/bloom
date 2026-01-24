//
//  UserConsentRecord.swift
//  Bloom-Backend
//
//  Created by Claude on 2025-01-29.
//

import Foundation
import Vapor
import Fluent

final class UserConsentRecord: Model, Content, @unchecked Sendable {
  static let schema = "user_consent_records"

  @ID(key: .id)
  var id: UUID?

  @Parent(key: "user_id")
  var user: User

  @Timestamp(key: "created_at", on: .create)
  var createdAt: Date?

  // UI Version Tracking
  @Field(key: "health_data_consent_screen_version")
  var healthDataConsentScreenVersion: String?

  @Field(key: "external_health_data_screen_version")
  var externalHealthDataScreenVersion: String?

  // General Health Data Consent
  @Field(key: "health_data_consent")
  var healthDataConsent: Bool?

  // Feature Consent
  @Field(key: "chat_with_bud_consent")
  var chatWithBudConsent: Bool?

  @Field(key: "today_insights_consent")
  var todayInsightsConsent: Bool?

  @Field(key: "monitor_consent")
  var monitorConsent: Bool?

  @Field(key: "biological_age_consent")
  var biologicalAgeConsent: Bool?

  // Health Category Consent
  @Field(key: "physical_activity_consent")
  var physicalActivityConsent: Bool?

  @Field(key: "body_metrics_consent")
  var bodyMetricsConsent: Bool?

  @Field(key: "mental_wellness_consent")
  var mentalWellnessConsent: Bool?

  @Field(key: "sleep_consent")
  var sleepConsent: Bool?

  @Field(key: "nutrition_consent")
  var nutritionConsent: Bool?

  @Field(key: "digestive_health_consent")
  var digestiveHealthConsent: Bool?

  @Field(key: "menstrual_health_consent")
  var menstrualHealthConsent: Bool?

  @Field(key: "lifestyle_consent")
  var lifestyleConsent: Bool?

  @Field(key: "demographics_consent")
  var demographicsConsent: Bool?

  @Field(key: "goals_consent")
  var goalsConsent: Bool?

  @Field(key: "location_consent")
  var locationConsent: Bool?

  @Field(key: "weather_consent")
  var weatherConsent: Bool?

  @Field(key: "calendar_events_consent")
  var calendarEventsConsent: Bool?

  init() { }

  init(
    id: UUID? = nil,
    userID: User.IDValue,
    healthDataConsentScreenVersion: String? = nil,
    externalHealthDataScreenVersion: String? = nil,
    healthDataConsent: Bool? = nil,
    chatWithBudConsent: Bool? = nil,
    todayInsightsConsent: Bool? = nil,
    monitorConsent: Bool? = nil,
    biologicalAgeConsent: Bool? = nil,
    physicalActivityConsent: Bool? = nil,
    bodyMetricsConsent: Bool? = nil,
    mentalWellnessConsent: Bool? = nil,
    sleepConsent: Bool? = nil,
    nutritionConsent: Bool? = nil,
    digestiveHealthConsent: Bool? = nil,
    menstrualHealthConsent: Bool? = nil,
    lifestyleConsent: Bool? = nil,
    demographicsConsent: Bool? = nil,
    goalsConsent: Bool? = nil,
    locationConsent: Bool? = nil,
    weatherConsent: Bool? = nil,
    calendarEventsConsent: Bool? = nil
  ) {
    self.id = id
    self.$user.id = userID
    self.healthDataConsentScreenVersion = healthDataConsentScreenVersion
    self.externalHealthDataScreenVersion = externalHealthDataScreenVersion
    self.healthDataConsent = healthDataConsent
    self.chatWithBudConsent = chatWithBudConsent
    self.todayInsightsConsent = todayInsightsConsent
    self.monitorConsent = monitorConsent
    self.biologicalAgeConsent = biologicalAgeConsent
    self.physicalActivityConsent = physicalActivityConsent
    self.bodyMetricsConsent = bodyMetricsConsent
    self.mentalWellnessConsent = mentalWellnessConsent
    self.sleepConsent = sleepConsent
    self.nutritionConsent = nutritionConsent
    self.digestiveHealthConsent = digestiveHealthConsent
    self.menstrualHealthConsent = menstrualHealthConsent
    self.lifestyleConsent = lifestyleConsent
    self.demographicsConsent = demographicsConsent
    self.goalsConsent = goalsConsent
    self.locationConsent = locationConsent
    self.weatherConsent = weatherConsent
    self.calendarEventsConsent = calendarEventsConsent
  }
}
