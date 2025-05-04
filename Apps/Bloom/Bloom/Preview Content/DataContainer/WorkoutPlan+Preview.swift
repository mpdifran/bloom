//
//  WorkoutPlan+Preview.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-28.
//

import DataContainer

extension WorkoutPlan {
  enum Preview { }
}

extension WorkoutPlan.Preview {
  nonisolated(unsafe) static let deadlifts = WorkoutPlan(
    id: "1234",
    title: "Deadlifts and Running",
    summary: "This workout focuses on building strength in your lower body using dumbbells and bodyweight exercises.",
    creationDate: .now,
    requiredEquipment: [.barbell],
    sets: [
      WorkoutSet(
        id: "1",
        title: "Warm Up",
        focus: "Warming up your body.",
        numberOfSets: 3,
        format: .warmup,
        duration: nil,
        restBetweenExercises: 30,
        appleWorkoutType: .preparationAndRecovery,
        exercises: [
          WorkoutExercise(
            id: "a",
            title: "Jumping Jacks",
            summary: "Jump to warm up!",
            numberOfReps: nil,
            distance: nil,
            distanceUnit: nil,
            duration: 60,
            kind: .exercise
          )
        ]
      ),
      WorkoutSet(
        id: "2",
        title: "Deadlifts",
        focus: "Posterior Chain.",
        numberOfSets: 5,
        format: .standard,
        duration: nil,
        restBetweenExercises: 60,
        appleWorkoutType: .traditionalStrengthTraining,
        exercises: [
          WorkoutExercise(
            id: "b",
            title: "Deadlift",
            summary: "Romanian deadlift, keep your weight on your heels.",
            numberOfReps: 8,
            distance: nil,
            distanceUnit: nil,
            duration: 180,
            kind: .exercise
          ),
          WorkoutExercise(
            id: "e",
            title: "Nordic Curls",
            summary: "Lower yourself to the ground using your hamstrings.",
            numberOfReps: 10,
            distance: nil,
            distanceUnit: nil,
            duration: 180,
            kind: .exercise
          )
        ]
      ),
      WorkoutSet(
        id: "3",
        title: "Running",
        focus: "Cardio.",
        numberOfSets: 1,
        format: .amrap,
        duration: 900,
        restBetweenExercises: 0,
        appleWorkoutType: .running,
        exercises: [
          WorkoutExercise(
            id: "c",
            title: "Run",
            summary: "Just run.",
            numberOfReps: nil,
            distance: 200,
            distanceUnit: .meter,
            duration: 300,
            kind: .exercise
          )
        ]
      ),
      WorkoutSet(
        id: "4",
        title: "Cool Down",
        focus: "Cooling down to avoid injury.",
        numberOfSets: 3,
        format: .coolDown,
        duration: nil,
        restBetweenExercises: 15,
        appleWorkoutType: .cooldown,
        exercises: [
          WorkoutExercise(
            id: "d",
            title: "Stretch legs",
            summary: "Avoid injury by stretching.",
            numberOfReps: 4,
            distance: nil,
            distanceUnit: nil,
            duration: 120,
            kind: .exercise
          )
        ]
      )
    ]
  )
}
