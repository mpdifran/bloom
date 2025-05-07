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
      "Not Started"
    case .running:
      "Running"
    case .ended:
      "Ended"
    case .paused:
      "Paused"
    case .prepared:
      "Prepared"
    case .stopped:
      "Stopped"
    @unknown default:
      "Unknown"
    }
  }
}
