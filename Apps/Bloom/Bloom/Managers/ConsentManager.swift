import Foundation
import OSLog
import SwiftUI
import TelemetryDeck
import BloomUI
import BloomModel
import CoreNetwork

@MainActor
final class ConsentManager: ObservableObject {
  static let shared = ConsentManager()

  @AppStorage("pendingHealthDataConsent") private var pendingHealthDataConsent: Bool?
  @AppStorage("pendingHealthDataConsentScreenVersion") private var pendingHealthDataConsentScreenVersion: String?

  private init() { }
}

extension ConsentManager {

  /// Records user consent for health data access and optional external processing.
  /// If user is authenticated, syncs immediately to backend.
  /// If user is not authenticated, stores locally for later sync.
  /// - Parameters:
  ///   - healthData: Whether user consents to health data access (typically true when called)
  ///   - healthDataConsentScreenVersion: The version of the screen used to ask for consent
  func recordConsent(healthData: Bool?, healthDataConsentScreenVersion: String) async throws {
    if UserController.shared.isAuthenticated {
      // User is authenticated - sync immediately to backend
      try await syncToBackend(healthData: healthData, healthDataConsentScreenVersion: healthDataConsentScreenVersion)
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
      biologicalAgeConsent: aiFeatures.biologicalAgeEnabled,
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

  /// Checks for pending consent and syncs to backend if user is authenticated.
  /// Call this after login or on app foreground.
  /// Silently fails and keeps pending consent for retry if sync fails.
  func syncPendingConsentIfNeeded() async {
    guard
      UserController.shared.isAuthenticated,
      pendingHealthDataConsent == true,
      let pendingHealthDataConsentScreenVersion
    else { return }

    do {
      try await syncToBackend(
        healthData: true,
        healthDataConsentScreenVersion: pendingHealthDataConsentScreenVersion
      )
      clearPendingConsent()
    } catch {
      // Keep pending consent in storage for next retry
      TelemetryDeck.errorOccurred(
        id: "ConsentManager.syncPendingConsentIfNeeded",
        category: .thrownException,
        message: error.localizedDescription
      )
    }
  }

  /// Clears any pending consent from local storage
  func clearPendingConsent() {
    pendingHealthDataConsent = nil
    pendingHealthDataConsentScreenVersion = nil
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
