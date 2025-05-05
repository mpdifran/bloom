//
//  HKWorkoutSessionState+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-05.
//

import HealthKit

extension HKWorkoutSessionState {
  var isActive: Bool {
    self != .notStarted && self != .ended
  }
}
