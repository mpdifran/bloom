//
//  WorkoutTemplate+Preview.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-28.
//

import DataContainer

extension WorkoutTemplate {
  enum Preview { }
}

extension WorkoutTemplate.Preview {
  nonisolated(unsafe) static let deadlifts = WorkoutTemplate(
    id: "1234",
    title: "Deadlifts and Running",
    creationDate: .now,
    appleWorkoutType: .traditionalStrengthTraining,
    requiredEquipment: [.barbell, .dumbbells, .treadmill],
    steps: [
      WorkoutStep(
        id: "1",
        title: "Deadlift",
        numberOfReps: 8,
        distance: nil,
        distanceUnit: nil,
        duration: 120,
        overrideAppleWorkoutType: nil,
        kind: .exercise
      ),
      WorkoutStep(
        id: "2",
        title: "Run",
        numberOfReps: nil,
        distance: 2,
        distanceUnit: .kilometer,
        duration: 180,
        overrideAppleWorkoutType: .running,
        kind: .exercise
      ),
      WorkoutStep(
        id: "3",
        title: "Deadlift",
        numberOfReps: 8,
        distance: nil,
        distanceUnit: nil,
        duration: 120,
        overrideAppleWorkoutType: nil,
        kind: .exercise
      ),
      WorkoutStep(
        id: "4",
        title: "Run",
        numberOfReps: nil,
        distance: 2,
        distanceUnit: .kilometer,
        duration: 180,
        overrideAppleWorkoutType: .running,
        kind: .exercise
      ),
      WorkoutStep(
        id: "5",
        title: "Rest",
        numberOfReps: nil,
        distance: nil,
        distanceUnit: nil,
        duration: 60,
        overrideAppleWorkoutType: .preparationAndRecovery,
        kind: .rest
      ),
      WorkoutStep(
        id: "6",
        title: "Deadlift",
        numberOfReps: 8,
        distance: nil,
        distanceUnit: nil,
        duration: 120,
        overrideAppleWorkoutType: nil,
        kind: .exercise
      ),
    ]
  )
}
