//
//  WorkoutStepV12.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-28.
//

import SwiftUI
import SwiftData
import HealthKit

extension SchemaV12 {
  @Model
  public final class WorkoutStep: Identifiable, Hashable {
    public var id: String
    public var title: String
    public var numberOfReps: Int?
    public var distance: Double?
    public var rawDistanceUnit: String?
    public var duration: TimeInterval
    public var rawOverrideAppleWorkoutType: String? = nil
    public var rawKind: String

    @Relationship public var workoutTemplate: WorkoutTemplate? = nil

    public init(
      id: String,
      title: String,
      numberOfReps: Int? = nil,
      distance: Double? = nil,
      distanceUnit: DistanceUnit? = nil,
      duration: TimeInterval,
      overrideAppleWorkoutType: HKWorkoutActivityType?,
      kind: Kind
    ) {
      self.id = id
      self.title = title
      self.numberOfReps = numberOfReps
      self.distance = distance
      self.rawDistanceUnit = distanceUnit?.rawValue
      self.duration = duration
      self.rawOverrideAppleWorkoutType = overrideAppleWorkoutType.map {
        "\($0.rawValue)"
      }
      self.rawKind = kind.rawValue
    }
  }
}

public extension SchemaV12.WorkoutStep {
  enum Kind: String, CaseIterable {
    case exercise
    case rest
  }

  enum DistanceUnit: String {
    case meter
    case kilometer
    case mile
    case yard
    case foot
  }
}
