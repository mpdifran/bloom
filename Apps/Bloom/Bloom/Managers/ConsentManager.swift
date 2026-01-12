import Foundation
import OSLog
import SwiftUI
import TelemetryDeck
import BloomUI
import BloomModel
import CoreNetwork

extension ConsentManager {
  enum ConsentType {
    case healthData
    case aiFeatures
  }
}

@MainActor
final class ConsentManager: ObservableObject {
  static let shared = ConsentManager()

  @AppStorage("pendingHealthDataConsent") private var pendingHealthDataConsent: Bool?
  @AppStorage("pendingHealthDataConsentScreenVersion") private var pendingHealthDataConsentScreenVersion: String?
  @AppStorage("pendingGranularConsent") private var pendingGranularConsent: Bool = false
  @AppStorage("hasCheckedConsentState") private var hasCheckedConsentState: Bool = false

  private init() { }
}

extension ConsentManager {

  /// Records user consent for health data access and optional external processing.
  /// If user is authenticated, syncs immediately to backend.
  /// If user is not authenticated, stores locally for later sync.
  /// - Parameters:
  ///   - healthData: Whether user consents to health data access (typically true when called)
  ///   - healthDataConsentScreenVersion: The version of the screen used to ask for consent
  func recordConsent(healthData: Bool?, healthDataConsentScreenVersion: String) async {
    if UserController.shared.isAuthenticated {
      // User is authenticated - sync immediately to backend
      do {
        try await syncToBackend(healthData: healthData, healthDataConsentScreenVersion: healthDataConsentScreenVersion)
      } catch {
        // Swallow error
        TelemetryDeck.errorOccurred(
          id: "ConsentManager.recordConsent",
          category: .thrownException,
          message: error.localizedDescription
        )
        storePendingConsent(healthData: healthData, healthDataConsentScreenVersion: healthDataConsentScreenVersion)
      }
    } else {
      // User not authenticated yet - store locally for later sync
      storePendingConsent(healthData: healthData, healthDataConsentScreenVersion: healthDataConsentScreenVersion)
    }
  }

  /// Records granular consent for AI features and data categories.
  /// Only sends to backend if user is authenticated.
  func recordGranularConsent(externalHealthDataScreenVersion: String) async throws {
    let aiFeatures = AIFeatureSettings.shared
    let aiDataSharing = AIDataSharingSettings.shared

    let request = UpdateConsentRequest(
      healthDataConsentScreenVersion: nil,
      externalHealthDataScreenVersion: externalHealthDataScreenVersion,
      healthDataConsent: true,
      chatWithBudConsent: aiFeatures.chatEnabled,
      todayInsightsConsent: aiFeatures.todayInsightsEnabled,
      biologicalAgeConsent: nil,
      physicalActivityConsent: aiDataSharing.enabledCategories.contains(.physicalActivity),
      bodyMetricsConsent: aiDataSharing.enabledCategories.contains(.bodyMetrics),
      mentalWellnessConsent: aiDataSharing.enabledCategories.contains(.mentalWellness),
      sleepConsent: aiDataSharing.enabledCategories.contains(.sleep),
      nutritionConsent: aiDataSharing.enabledCategories.contains(.nutrition),
      digestiveHealthConsent: aiDataSharing.enabledCategories.contains(.digestiveHealth),
      menstrualHealthConsent: aiDataSharing.enabledCategories.contains(.menstrualHealth),
      demographicsConsent: aiDataSharing.enabledCategories.contains(.demographics),
      goalsConsent: aiDataSharing.enabledCategories.contains(.goals),
      locationConsent: aiDataSharing.enabledCategories.contains(.location),
      weatherConsent: aiDataSharing.enabledCategories.contains(.weather),
      calendarEventsConsent: aiDataSharing.enabledCategories.contains(.calendarEvents)
    )

    let _ = try await NetworkRequester.shared.updateConsent(request: request)
  }

  func recordGranularConsentUpdate() async throws {
    let aiFeatures = AIFeatureSettings.shared
    let aiDataSharing = AIDataSharingSettings.shared

    let request = UpdateConsentRequest(
      healthDataConsentScreenVersion: nil,
      externalHealthDataScreenVersion: nil,
      healthDataConsent: true,
      chatWithBudConsent: aiFeatures.chatEnabled,
      todayInsightsConsent: aiFeatures.todayInsightsEnabled,
      biologicalAgeConsent: nil,
      physicalActivityConsent: aiDataSharing.enabledCategories.contains(.physicalActivity),
      bodyMetricsConsent: aiDataSharing.enabledCategories.contains(.bodyMetrics),
      mentalWellnessConsent: aiDataSharing.enabledCategories.contains(.mentalWellness),
      sleepConsent: aiDataSharing.enabledCategories.contains(.sleep),
      nutritionConsent: aiDataSharing.enabledCategories.contains(.nutrition),
      digestiveHealthConsent: aiDataSharing.enabledCategories.contains(.digestiveHealth),
      menstrualHealthConsent: aiDataSharing.enabledCategories.contains(.menstrualHealth),
      demographicsConsent: aiDataSharing.enabledCategories.contains(.demographics),
      goalsConsent: aiDataSharing.enabledCategories.contains(.goals),
      locationConsent: aiDataSharing.enabledCategories.contains(.location),
      weatherConsent: aiDataSharing.enabledCategories.contains(.weather),
      calendarEventsConsent: aiDataSharing.enabledCategories.contains(.calendarEvents)
    )

    let _ = try await NetworkRequester.shared.updateConsent(request: request)
  }

  /// Syncs granular consent silently. On failure, sets pending flag for retry.
  /// Call this when user changes settings (on view disappear or app background).
  func syncGranularConsentSilently() async {
    guard UserController.shared.isAuthenticated else {
      pendingGranularConsent = true
      return
    }

    do {
      try await recordGranularConsentUpdate()
      pendingGranularConsent = false
    } catch {
      pendingGranularConsent = true
      TelemetryDeck.errorOccurred(
        id: "ConsentManager.syncGranularConsentSilently",
        category: .thrownException,
        message: error.localizedDescription
      )
    }
  }

  /// Checks if user has any unknown consent states that need to be addressed.
  /// Returns true if PrivacyUnknownOptInView should be shown.
  func missingConsentStates() async -> [ConsentType] {
    guard !hasCheckedConsentState else { return [] }
    guard UserController.shared.isAuthenticated else { return [] }

    do {
      let response = try await NetworkRequester.shared.getConsent()

      // Check if any feature consent fields are nil (unknown)
      // Individual checks to avoid slow type inference from chained ||
      let unknownChat: Bool = response.chatWithBudConsent == nil
      let unknownInsights: Bool = response.todayInsightsConsent == nil
      let hasUnknownFeatures = unknownChat || unknownInsights

      // Check if any health data category consent fields are nil (unknown)
      let unknownPhysical: Bool = response.physicalActivityConsent == nil
      let unknownBody: Bool = response.bodyMetricsConsent == nil
      let unknownMental: Bool = response.mentalWellnessConsent == nil
      let unknownSleep: Bool = response.sleepConsent == nil
      let unknownNutrition: Bool = response.nutritionConsent == nil
      let unknownDigestive: Bool = response.digestiveHealthConsent == nil
      let unknownMenstrual: Bool = response.menstrualHealthConsent == nil
      let unknownDemographics: Bool = response.demographicsConsent == nil
      let unknownGoals: Bool = response.goalsConsent == nil
      let unknownLocation: Bool = response.locationConsent == nil
      let unknownWeather: Bool = response.weatherConsent == nil
      let unknownCalendar: Bool = response.calendarEventsConsent == nil

      let hasUnknownCategories = unknownPhysical || unknownBody || unknownMental ||
                                  unknownSleep || unknownNutrition || unknownDigestive
      let hasUnknownCategories2 = unknownMenstrual || unknownDemographics || unknownGoals ||
                                   unknownLocation || unknownWeather || unknownCalendar

      var consentTypes = [ConsentType]()
      if response.healthDataConsent == nil {
        consentTypes.append(.healthData)
      }
      if (hasUnknownFeatures || hasUnknownCategories || hasUnknownCategories2)
          && EntitlementController.shared.hasBloomPro == true {
        consentTypes.append(.aiFeatures)
      }
      return consentTypes
    } catch {
      return []
    }
  }

  func markConsentAsChecked() {
    hasCheckedConsentState = true
  }

  /// Checks for pending consent and syncs to backend if user is authenticated.
  /// Call this after login or on app foreground.
  /// Silently fails and keeps pending consent for retry if sync fails.
  func syncPendingConsentIfNeeded() async {
    guard UserController.shared.isAuthenticated else { return }

    // Sync pending health data consent
    if pendingHealthDataConsent == true, let pendingHealthDataConsentScreenVersion {
      do {
        try await syncToBackend(
          healthData: true,
          healthDataConsentScreenVersion: pendingHealthDataConsentScreenVersion
        )
        self.pendingHealthDataConsent = nil
        self.pendingHealthDataConsentScreenVersion = nil
      } catch {
        TelemetryDeck.errorOccurred(
          id: "ConsentManager.syncPendingConsentIfNeeded",
          category: .thrownException,
          message: error.localizedDescription
        )
      }
    }

    // Sync pending granular consent
    if pendingGranularConsent {
      do {
        try await recordGranularConsentUpdate()
        pendingGranularConsent = false
      } catch {
        TelemetryDeck.errorOccurred(
          id: "ConsentManager.syncPendingGranularConsent",
          category: .thrownException,
          message: error.localizedDescription
        )
      }
    }
  }

  /// Clears any pending consent from local storage
  func clearPendingConsent() {
    pendingHealthDataConsent = nil
    pendingHealthDataConsentScreenVersion = nil
    pendingGranularConsent = false
  }
}

// MARK: - Private Helpers

private extension ConsentManager {

  func storePendingConsent(healthData: Bool?, healthDataConsentScreenVersion: String) {
    if let healthData {
      pendingHealthDataConsent = healthData
    }
    pendingHealthDataConsentScreenVersion = healthDataConsentScreenVersion
  }

  func syncToBackend(healthData: Bool?, healthDataConsentScreenVersion: String) async throws {
    let request = UpdateConsentRequest(
      healthDataConsentScreenVersion: healthDataConsentScreenVersion,
      externalHealthDataScreenVersion: nil,
      healthDataConsent: true,
      chatWithBudConsent: nil,
      todayInsightsConsent: nil,
      biologicalAgeConsent: nil,
      physicalActivityConsent: nil,
      bodyMetricsConsent: nil,
      mentalWellnessConsent: nil,
      sleepConsent: nil,
      nutritionConsent: nil,
      digestiveHealthConsent: nil,
      menstrualHealthConsent: nil,
      demographicsConsent: nil,
      goalsConsent: nil,
      locationConsent: nil,
      weatherConsent: nil,
      calendarEventsConsent: nil
    )

    let _ = try await NetworkRequester.shared.updateConsent(request: request)
  }
}
