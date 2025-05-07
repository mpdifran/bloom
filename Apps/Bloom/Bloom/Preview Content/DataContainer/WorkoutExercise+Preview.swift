//
//  WorkoutExercise+Preview.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-07.
//

import DataContainer

extension WorkoutExercise {
  enum Preview { }
}

extension WorkoutExercise.Preview {
  nonisolated(unsafe) static let deadlifts = WorkoutExercise(
    id: "b",
    index: 0,
    title: "Deadlift",
    summary: "Romanian deadlift, keep your weight on your heels.",
    numberOfReps: 8,
    distance: nil,
    distanceUnit: nil,
    duration: 180,
    kind: .exercise
  )
}
