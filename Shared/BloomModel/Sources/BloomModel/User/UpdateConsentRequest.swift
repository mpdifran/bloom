//
//  UpdateConsentRequest.swift
//  bloom-model
//
//  Created by Assistant on 2025-11-12.
//

public struct UpdateConsentRequest: Codable, Hashable, Sendable {
  // UI Version Tracking
  /// Version string for the health data consent screen presented to the user
  public let healthDataConsentScreenVersion: String?
  /// Version string for the external health data processing consent screen presented to the user
  public let externalHealthDataScreenVersion: String?

  // General Health Data Consent
  /// Whether the user has granted consent to access general health data
  public let healthDataConsent: Bool?

  // Feature Consent
  /// Whether the user has granted consent for Chat with Bud feature
  public let chatWithBudConsent: Bool?
  /// Whether the user has granted consent for Today Insights feature
  public let todayInsightsConsent: Bool?
  /// Whether the user has granted consent for Biological Age feature
  public let biologicalAgeConsent: Bool?

  // Health Category Consent
  /// Whether the user has granted consent for physical activity data
  public let physicalActivityConsent: Bool?
  /// Whether the user has granted consent for body metrics data
  public let bodyMetricsConsent: Bool?
  /// Whether the user has granted consent for mental wellness data
  public let mentalWellnessConsent: Bool?
  /// Whether the user has granted consent for sleep data
  public let sleepConsent: Bool?
  /// Whether the user has granted consent for nutrition data
  public let nutritionConsent: Bool?
  /// Whether the user has granted consent for digestive health data
  public let digestiveHealthConsent: Bool?
  /// Whether the user has granted consent for menstrual health data
  public let menstrualHealthConsent: Bool?
  /// Whether the user has granted consent for demographics data
  public let demographicsConsent: Bool?
  /// Whether the user has granted consent for goals data
  public let goalsConsent: Bool?
  /// Whether the user has granted consent for location data
  public let locationConsent: Bool?
  /// Whether the user has granted consent for weather data
  public let weatherConsent: Bool?
  /// Whether the user has granted consent for calendar events data
  public let calendarEventsConsent: Bool?

  public init(
    healthDataConsentScreenVersion: String? = nil,
    externalHealthDataScreenVersion: String? = nil,
    healthDataConsent: Bool? = nil,
    chatWithBudConsent: Bool? = nil,
    todayInsightsConsent: Bool? = nil,
    biologicalAgeConsent: Bool? = nil,
    physicalActivityConsent: Bool? = nil,
    bodyMetricsConsent: Bool? = nil,
    mentalWellnessConsent: Bool? = nil,
    sleepConsent: Bool? = nil,
    nutritionConsent: Bool? = nil,
    digestiveHealthConsent: Bool? = nil,
    menstrualHealthConsent: Bool? = nil,
    demographicsConsent: Bool? = nil,
    goalsConsent: Bool? = nil,
    locationConsent: Bool? = nil,
    weatherConsent: Bool? = nil,
    calendarEventsConsent: Bool? = nil
  ) {
    self.healthDataConsentScreenVersion = healthDataConsentScreenVersion
    self.externalHealthDataScreenVersion = externalHealthDataScreenVersion
    self.healthDataConsent = healthDataConsent
    self.chatWithBudConsent = chatWithBudConsent
    self.todayInsightsConsent = todayInsightsConsent
    self.biologicalAgeConsent = biologicalAgeConsent
    self.physicalActivityConsent = physicalActivityConsent
    self.bodyMetricsConsent = bodyMetricsConsent
    self.mentalWellnessConsent = mentalWellnessConsent
    self.sleepConsent = sleepConsent
    self.nutritionConsent = nutritionConsent
    self.digestiveHealthConsent = digestiveHealthConsent
    self.menstrualHealthConsent = menstrualHealthConsent
    self.demographicsConsent = demographicsConsent
    self.goalsConsent = goalsConsent
    self.locationConsent = locationConsent
    self.weatherConsent = weatherConsent
    self.calendarEventsConsent = calendarEventsConsent
  }
}
