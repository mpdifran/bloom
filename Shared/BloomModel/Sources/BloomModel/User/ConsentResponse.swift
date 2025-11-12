//
//  ConsentResponse.swift
//  bloom-model
//
//  Created by Assistant on 2025-11-12.
//

public struct ConsentResponse: Codable, Hashable, Sendable {
  /// Whether the user has granted consent to access general health data
  public let hasHealthDataConsent: Bool
  /// Whether the user has granted consent for external processing of health data on the backend
  public let hasExternalProcessingConsent: Bool

  public init(
    hasHealthDataConsent: Bool,
    hasExternalProcessingConsent: Bool
  ) {
    self.hasHealthDataConsent = hasHealthDataConsent
    self.hasExternalProcessingConsent = hasExternalProcessingConsent
  }
}
