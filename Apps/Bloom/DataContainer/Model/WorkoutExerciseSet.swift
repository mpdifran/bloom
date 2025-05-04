//
//  WorkoutExerciseSet.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-03.
//

import Foundation

public extension WorkoutExerciseSet {
  enum Kind: Hashable {
    case exercise(WorkoutExercise)
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
    self.kind = .exercise(exercise)
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
