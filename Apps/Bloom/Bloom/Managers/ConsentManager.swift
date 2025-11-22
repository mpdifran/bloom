import Foundation
import OSLog
import SwiftUI
import TelemetryDeck

@MainActor
final class ConsentManager: ObservableObject {
  static let shared = ConsentManager()

  @AppStorage("pendingHealthDataConsent") private var pendingHealthDataConsent: Bool?
  @AppStorage("pendingExternalProcessingConsent") private var pendingExternalProcessingConsent: Bool?

  private init() { }
}

extension ConsentManager {

  /// Records user consent for health data access and optional external processing.
  /// If user is authenticated, syncs immediately to backend.
  /// If user is not authenticated, stores locally for later sync.
  /// - Parameters:
  ///   - healthData: Whether user consents to health data access (typically true when called)
  ///   - externalProcessing: Whether user consents to external processing of health data on backend
  func recordConsent(healthData: Bool?, externalProcessing: Bool?) async throws {
    if UserController.shared.isAuthenticated {
      // User is authenticated - sync immediately to backend
      try await syncToBackend(healthData: healthData, externalProcessing: externalProcessing)
    } else {
      // User not authenticated yet - store locally for later sync
      storePendingConsent(healthData: healthData, externalProcessing: externalProcessing)
    }
  }

  /// Checks for pending consent and syncs to backend if user is authenticated.
  /// Call this after login or on app foreground.
  /// Silently fails and keeps pending consent for retry if sync fails.
  func syncPendingConsentIfNeeded() async {
    guard UserController.shared.isAuthenticated else { return }
    guard pendingHealthDataConsent == true else { return }

    do {
      try await syncToBackend(
        healthData: true,
        externalProcessing: pendingExternalProcessingConsent
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
    pendingExternalProcessingConsent = nil
  }
}

// MARK: - Private Helpers

private extension ConsentManager {

  func storePendingConsent(healthData: Bool?, externalProcessing: Bool?) {
    if let healthData {
      pendingHealthDataConsent = healthData
    }
    if let externalProcessing {
      pendingExternalProcessingConsent = externalProcessing
    }
  }

  func syncToBackend(healthData: Bool?, externalProcessing: Bool?) async throws {
    let _ = try await UserController.shared.updateConsent(
      healthData: healthData,
      externalProcessing: externalProcessing
    )
  }
}
