//
//  WorkoutExerciseSet+Preview.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-07.
//

import DataContainer

extension WorkoutExerciseSet {
  enum Preview { }
}

extension WorkoutExerciseSet.Preview {
  nonisolated(unsafe) static let deadlifts = WorkoutExerciseSet(
    set: .Preview.deadlifts,
    exercise: WorkoutSet.Preview.deadlifts.exercises![0],
    setNumber: 0
  )

  nonisolated(unsafe) static let amrap = WorkoutExerciseSet(
    set: .Preview.amrap,
    exercises: WorkoutSet.Preview.amrap.exercises ?? [],
    format: .amrap,
    setNumber: 0
  )

  nonisolated(unsafe) static let emom = WorkoutExerciseSet(
    set: .Preview.emom,
    exercises: WorkoutSet.Preview.emom.exercises ?? [],
    format: .emom,
    setNumber: 0
  )

  nonisolated(unsafe) static let tabata = WorkoutExerciseSet(
    set: .Preview.tabata,
    exercises: WorkoutSet.Preview.tabata.exercises ?? [],
    format: .tabata,
    setNumber: 0
  )
}
