//
//  HKWorkoutSessionState+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-05.
//

import HealthKit

public extension HKWorkoutSessionState {
  var isActive: Bool {
    self != .notStarted && self != .ended
  }

  var name: String {
    switch self {
    case .notStarted:
      String(localized: "Not Started", bundle: Bundle.coreHealth)
    case .running:
      String(localized: "Running", bundle: Bundle.coreHealth)
    case .ended:
      String(localized: "Ended", bundle: Bundle.coreHealth)
    case .paused:
      String(localized: "Paused", bundle: Bundle.coreHealth)
    case .prepared:
      String(localized: "Prepared", bundle: Bundle.coreHealth)
    case .stopped:
      String(localized: "Stopped", bundle: Bundle.coreHealth)
    @unknown default:
      String(localized: "Unknown", bundle: Bundle.coreHealth)
    }
  }
}
