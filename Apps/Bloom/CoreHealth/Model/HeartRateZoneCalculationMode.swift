//
//  HeartRateZoneCalculationMode.swift
//  CoreHealth
//
//  Created by Claude on 2026-02-04.
//

import Foundation

public enum HeartRateZoneCalculationMode: String, CaseIterable, Codable, Sendable {
  case automatic
  case semiManual
  case manual

  public var displayName: String {
    switch self {
    case .automatic:
      return "Automatic"
    case .semiManual:
      return "Custom HR"
    case .manual:
      return "Custom Zones"
    }
  }

  public var description: String {
    switch self {
    case .automatic:
      return "Zones calculated from your age and resting heart rate from HealthKit"
    case .semiManual:
      return "Set your max and resting heart rate, zones calculated as percentages"
    case .manual:
      return "Set each zone threshold individually"
    }
  }
}
