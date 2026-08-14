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
      return String(localized: "Automatic", bundle: Bundle.coreHealth, comment: "Display name for heart rate zone calculation mode")
    case .semiManual:
      return String(localized: "Custom HR", bundle: Bundle.coreHealth, comment: "Display name for heart rate zone calculation mode")
    case .manual:
      return String(localized: "Custom Zones", bundle: Bundle.coreHealth, comment: "Display name for heart rate zone calculation mode")
    }
  }

  public var description: String {
    switch self {
    case .automatic:
      return String(localized: "Zones calculated from your age and resting heart rate from HealthKit", bundle: Bundle.coreHealth, comment: "Description for heart rate zone calculation mode")
    case .semiManual:
      return String(localized: "Set your max and resting heart rate, zones calculated as percentages", bundle: Bundle.coreHealth, comment: "Description for heart rate zone calculation mode")
    case .manual:
      return String(localized: "Set each zone threshold individually", bundle: Bundle.coreHealth, comment: "Description for heart rate zone calculation mode")
    }
  }
}
