//
//  SocketMessageWorkoutTemplate+Preview.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-29.
//

import BloomModel

extension SocketMessage.WorkoutTemplate {
  enum Preview { }
}

extension SocketMessage.WorkoutTemplate.Preview {
  static let deadlifts = SocketMessage.WorkoutTemplate(
    title: "Deadlifts and Running",
    appleWorkoutType: .traditionalStrengthTraining,
    requiredEquipment: [.barbell],
    steps: [
      SocketMessage.WorkoutStep(
        title: "Deadlift",
        numberOfReps: 8,
        distance: nil,
        distanceUnit: nil,
        duration: 120,
        overrideAppleWorkoutType: nil,
        kind: .exercise
      ),
      SocketMessage.WorkoutStep(
        title: "Run",
        numberOfReps: nil,
        distance: 2,
        distanceUnit: .kilometer,
        duration: nil,
        overrideAppleWorkoutType: .running,
        kind: .exercise
      ),
      SocketMessage.WorkoutStep(
        title: "Deadlift",
        numberOfReps: 8,
        distance: nil,
        distanceUnit: nil,
        duration: 120,
        overrideAppleWorkoutType: nil,
        kind: .exercise
      ),
      SocketMessage.WorkoutStep(
        title: "Run",
        numberOfReps: nil,
        distance: 2,
        distanceUnit: .kilometer,
        duration: nil,
        overrideAppleWorkoutType: .running,
        kind: .exercise
      ),
      SocketMessage.WorkoutStep(
        title: "Deadlift",
        numberOfReps: 8,
        distance: nil,
        distanceUnit: nil,
        duration: 120,
        overrideAppleWorkoutType: nil,
        kind: .exercise
      )
    ]
  )
}
