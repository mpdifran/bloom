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
      "Not Set"
    case .never:
      "Never Smoked"
    case .former:
      "Former Smoker"
    case .current:
      "Current Smoker"
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
