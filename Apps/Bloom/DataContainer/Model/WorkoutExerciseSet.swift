//
//  WorkoutExerciseSet.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-03.
//

import Foundation

public extension WorkoutExerciseSet {
  enum Kind: Hashable {
    case standard(WorkoutExercise)
    case grouped([WorkoutExercise], WorkoutSet.Format)
    case rest(TimeInterval)
  }
}

public struct WorkoutExerciseSet: Identifiable, Hashable {
  public let id: String
  public let set: WorkoutSet
  public let kind: Kind
  public let setNumber: Int

  public init(
    set: WorkoutSet,
    exercise: WorkoutExercise,
    setNumber: Int
  ) {
    self.id = UUID().uuidString
    self.set = set
    self.kind = .standard(exercise)
    self.setNumber = setNumber
  }

  public init(
    set: WorkoutSet,
    exercises: [WorkoutExercise],
    format: WorkoutSet.Format,
    setNumber: Int
  ) {
    self.id = UUID().uuidString
    self.set = set
    self.kind = .grouped(exercises, format)
    self.setNumber = setNumber
  }

  public init(
    set: WorkoutSet,
    rest: TimeInterval,
    setNumber: Int
  ) {
    self.id = UUID().uuidString
    self.set = set
    self.kind = .rest(rest)
    self.setNumber = setNumber
  }
}
