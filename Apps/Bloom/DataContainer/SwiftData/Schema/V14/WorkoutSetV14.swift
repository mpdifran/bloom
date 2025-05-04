//
//  WorkoutSetV14.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-04.
//

import SwiftUI
import SwiftData
import HealthKit

// https://www.hackingwithswift.com/books/ios-swiftui/syncing-swiftdata-with-cloudkit
// For CloudKit sync to work, all properties must be optional or have default values, and all relationship must be optional.

extension SchemaV14 {
  @Model
  public final class WorkoutSet: Identifiable, Hashable {
    public var id: String
    public var index: Int = 0
    public var title: String
    public var focus: String
    public var numberOfSets: Int
    public var rawFormat: String
    public var duration: TimeInterval?
    public var restBetweenExercises: TimeInterval
    public var rawAppleWorkoutType: String? = nil

    @Relationship public var plan: WorkoutPlan? = nil
    @Relationship public var exercises: [WorkoutExercise]? = []

    public init(
      id: String,
      index: Int,
      title: String,
      focus: String,
      numberOfSets: Int,
      format: WorkoutSet.Format,
      duration: TimeInterval?,
      restBetweenExercises: TimeInterval,
      appleWorkoutType: HKWorkoutActivityType,
      exercises: [WorkoutExercise] = []
    ) {
      self.id = id
      self.index = index
      self.title = title
      self.focus = focus
      self.numberOfSets = numberOfSets
      self.rawFormat = "\(format.rawValue)"
      self.duration = duration
      self.restBetweenExercises = restBetweenExercises
      self.rawAppleWorkoutType = "\(appleWorkoutType.rawValue)"
      self.exercises = exercises
    }
  }
}
