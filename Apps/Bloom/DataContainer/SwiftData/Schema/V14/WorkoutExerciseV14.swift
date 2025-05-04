//
//  WorkoutExerciseV14.swift
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
  public final class WorkoutExercise: Identifiable, Hashable {
    public var id: String
    public var index: Int = 0
    public var title: String
    public var summary: String
    public var numberOfReps: Int?
    public var distance: Double?
    public var rawDistanceUnit: String?
    public var duration: TimeInterval
    public var rawKind: String

    @Relationship public var set: WorkoutSet? = nil

    public init(
      id: String,
      index: Int,
      title: String,
      summary: String,
      numberOfReps: Int?,
      distance: Double?,
      distanceUnit: DistanceUnit?,
      duration: TimeInterval,
      kind: Kind
    ) {
      self.id = id
      self.index = index
      self.title = title
      self.summary = summary
      self.numberOfReps = numberOfReps
      self.distance = distance
      self.rawDistanceUnit = distanceUnit?.rawValue
      self.duration = duration
      self.rawKind = kind.rawValue
    }
  }
}
