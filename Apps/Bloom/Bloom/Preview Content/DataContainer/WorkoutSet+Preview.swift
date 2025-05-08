//
//  WorkoutSet+Preview.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-07.
//

import DataContainer

extension WorkoutSet {
  enum Preview { }
}

extension WorkoutSet.Preview {
  nonisolated(unsafe) static let deadlifts = WorkoutSet(
    id: "2",
    index: 1,
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
        index: 0,
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
        index: 1,
        title: "Nordic Curls",
        summary: "Lower yourself to the ground using your hamstrings.",
        numberOfReps: 10,
        distance: nil,
        distanceUnit: nil,
        duration: 180,
        kind: .exercise
      )
    ]
  )

  nonisolated(unsafe) static let amrap = WorkoutSet(
    id: "2",
    index: 0,
    title: "AMRAP Set",
    focus: "Heart Rate.",
    numberOfSets: 1,
    format: .amrap,
    duration: 900,
    restBetweenExercises: 0,
    appleWorkoutType: .highIntensityIntervalTraining,
    exercises: [
      WorkoutExercise(
        id: "a",
        index: 0,
        title: "Run",
        summary: "Run 200 meters",
        numberOfReps: nil,
        distance: 200,
        distanceUnit: .meter,
        duration: 180,
        kind: .exercise
      ),
      WorkoutExercise(
        id: "b",
        index: 1,
        title: "Jumping Jacks",
        summary: "Get your heart rate up!",
        numberOfReps: 20,
        distance: nil,
        distanceUnit: nil,
        duration: 60,
        kind: .exercise
      ),
      WorkoutExercise(
        id: "c",
        index: 2,
        title: "Push Ups",
        summary: "Push yourself up from the ground.",
        numberOfReps: 10,
        distance: nil,
        distanceUnit: nil,
        duration: 60,
        kind: .exercise
      )
    ]
  )

  nonisolated(unsafe) static let emom = WorkoutSet(
    id: "2",
    index: 0,
    title: "EMOM Set",
    focus: "Doing something every minute",
    numberOfSets: 1,
    format: .emom,
    duration: 600,
    restBetweenExercises: 0,
    appleWorkoutType: .highIntensityIntervalTraining,
    exercises: [
      WorkoutExercise(
        id: "b",
        index: 0,
        title: "Jumping Jacks",
        summary: "Get your heart rate up!",
        numberOfReps: 10,
        distance: nil,
        distanceUnit: nil,
        duration: 20,
        kind: .exercise
      ),
      WorkoutExercise(
        id: "c",
        index: 1,
        title: "Push Ups",
        summary: "Push yourself up from the ground.",
        numberOfReps: 5,
        distance: nil,
        distanceUnit: nil,
        duration: 20,
        kind: .exercise
      )
    ]
  )

  nonisolated(unsafe) static let tabata = WorkoutSet(
    id: "2",
    index: 0,
    title: "Tabata Bicep Curls",
    focus: "Strengthen the biceps.",
    numberOfSets: 1,
    format: .tabata,
    duration: 480,
    restBetweenExercises: 0,
    appleWorkoutType: .functionalStrengthTraining,
    exercises: [
      WorkoutExercise(
        id: "b",
        index: 0,
        title: "Bicep Curls",
        summary: "Curl your biceps without moving your body.",
        numberOfReps: nil,
        distance: nil,
        distanceUnit: nil,
        duration: 20,
        kind: .exercise
      )
    ]
  )
}
