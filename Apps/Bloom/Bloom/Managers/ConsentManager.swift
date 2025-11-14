import Foundation
import OSLog

@MainActor
final class ConsentManager: ObservableObject {
  static let shared = ConsentManager()

  private init() { }
}

extension ConsentManager {

  /// Records user consent for health data access and optional external processing
  /// - Parameters:
  ///   - healthData: Whether user consents to health data access (typically true when called)
  ///   - externalProcessing: Whether user consents to external processing of health data on backend
  func recordConsent(healthData: Bool, externalProcessing: Bool?) async throws {
    let _ = try await UserController.shared.updateConsent(
      healthData: healthData,
      externalProcessing: externalProcessing
    )
  }
}
