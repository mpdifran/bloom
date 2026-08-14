//
//  SmokingStatus.swift
//  CoreHealth
//
//  Created by Claude on 2026-01-24.
//

import Foundation

public enum SmokingStatus: String, CaseIterable, Codable, Sendable {
  case unknown
  case never
  case former
  case current

  public var displayName: String {
    switch self {
    case .unknown:
      String(localized: "Not Set", bundle: Bundle.coreHealth, comment: "Display name for smoking status")
    case .never:
      String(localized: "Never Smoked", bundle: Bundle.coreHealth, comment: "Display name for smoking status")
    case .former:
      String(localized: "Former Smoker", bundle: Bundle.coreHealth, comment: "Display name for smoking status")
    case .current:
      String(localized: "Current Smoker", bundle: Bundle.coreHealth, comment: "Display name for smoking status")
    }
  }

  public var shortDisplayName: String {
    switch self {
    case .unknown:
      "Not Set"
    case .never:
      "Never"
    case .former:
      "Former"
    case .current:
      "Current"
    }
  }
}
