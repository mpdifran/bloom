//
//  UpdateConsentRequest.swift
//  bloom-model
//
//  Created by Assistant on 2025-11-12.
//

public struct UpdateConsentRequest: Codable, Hashable, Sendable {
  /// Whether the user has granted consent to access general health data
  public let healthDataConsent: Bool?
  /// Whether the user has granted consent for external processing of health data on the backend
  public let externalProcessingConsent: Bool?

  public init(
    healthDataConsent: Bool? = nil,
    externalProcessingConsent: Bool? = nil
  ) {
    self.healthDataConsent = healthDataConsent
    self.externalProcessingConsent = externalProcessingConsent
  }
}
