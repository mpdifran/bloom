//
//  CompletedWorkoutSegment.swift
//  Bloom
//
//  Created by Mark DiFranco on 2026-03-31.
//

import Foundation
import HealthKit

/// Represents a completed workout segment within a multi-workout session.
/// Captures the HKWorkout plus the zone durations that were tracked during
/// that segment, since zone data is reset between switches.
public struct CompletedWorkoutSegment: Identifiable, Sendable {
  public let id = UUID()
  public let workout: HKWorkout
  public let zoneDurations: [TimeInterval] // indices 0-5

  public init(workout: HKWorkout, zoneDurations: [TimeInterval]) {
    self.workout = workout
    self.zoneDurations = zoneDurations
  }
}
