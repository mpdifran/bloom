//
//  GenerateWorkoutPlanResponse.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2026-02-11.
//

import Foundation

public struct GenerateWorkoutPlanResponse: Codable, Equatable, Sendable {
  public let workoutPlan: SocketMessage.WorkoutPlan

  public init(workoutPlan: SocketMessage.WorkoutPlan) {
    self.workoutPlan = workoutPlan
  }
}
