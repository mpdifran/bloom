//
//  SocketMessageWorkoutTemplate+Preview.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-29.
//

import BloomModel

extension SocketMessage.WorkoutPlan {
  enum Preview { }
}

extension SocketMessage.WorkoutPlan.Preview {
  static let deadlifts = SocketMessage.WorkoutPlan(
    title: "Deadlifts and Running",
    summary: "This workout focuses on building strength in your lower body using dumbbells and bodyweight exercises.",
    requiredEquipment: [.barbell],
    sets: [
      SocketMessage.WorkoutSet(
        title: "Warm Up",
        focus: "Warming up your body.",
        numberOfSets: 3,
        format: .warmup,
        duration: nil,
        appleWorkoutType: .preparationAndRecovery,
        restBetweenExercises: 30,
        exercises: [
          SocketMessage.WorkoutExercise(
            title: "Jumping Jacks",
            instructions: "Jump to warm up!",
            numberOfReps: nil,
            distance: nil,
            distanceUnit: nil,
            duration: 60
          )
        ]
      ),
      SocketMessage.WorkoutSet(
        title: "Strength Training",
        focus: "Posterior Chain.",
        numberOfSets: 5,
        format: .standard,
        duration: nil,
        appleWorkoutType: .traditionalStrengthTraining,
        restBetweenExercises: 60,
        exercises: [
          SocketMessage.WorkoutExercise(
            title: "Deadlift",
            instructions: "Romanian deadlift, keep your weight on your heels.",
            numberOfReps: 8,
            distance: nil,
            distanceUnit: nil,
            duration: 180
          ),
          SocketMessage.WorkoutExercise(
            title: "Nordic Curls",
            instructions: "Lower yourself to the ground using your hamstrings.",
            numberOfReps: 10,
            distance: nil,
            distanceUnit: nil,
            duration: 180
          )
        ]
      ),
      SocketMessage.WorkoutSet(
        title: "Running",
        focus: "Cardio.",
        numberOfSets: 4,
        format: .amrap,
        duration: 900,
        appleWorkoutType: .running,
        restBetweenExercises: 0,
        exercises: [
          SocketMessage.WorkoutExercise(
            title: "Run",
            instructions: "Just run.",
            numberOfReps: 1,
            distance: 200,
            distanceUnit: .meter,
            duration: 300
          )
        ]
      ),
      SocketMessage.WorkoutSet(
        title: "Cool Down",
        focus: "Cooling down to avoid injury.",
        numberOfSets: 3,
        format: .cooldown,
        duration: nil,
        appleWorkoutType: .cooldown,
        restBetweenExercises: 15,
        exercises: [
          SocketMessage.WorkoutExercise(
            title: "Stretch legs",
            instructions: "Avoid injury by stretching.",
            numberOfReps: 4,
            distance: nil,
            distanceUnit: nil,
            duration: 120
          )
        ]
      )
    ]
  )
}
