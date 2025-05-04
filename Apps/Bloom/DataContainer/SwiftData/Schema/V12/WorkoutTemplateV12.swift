//
//  WorkoutTemplateV12.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-28.
//

import SwiftUI
import SwiftData
import HealthKit

// https://www.hackingwithswift.com/books/ios-swiftui/syncing-swiftdata-with-cloudkit
// For CloudKit sync to work, all properties must be optional or have default values, and all relationship must be optional.

extension SchemaV12 {
  @Model
  public final class WorkoutTemplate: Identifiable, Hashable {
    public var id: String
    public var title: String
    public var creationDate: Date
    public var rawAppleWorkoutType: String
    public var rawRequiredEquipment: [String]

    @Relationship public var steps: [WorkoutStep]? = []

    public init(
      id: String,
      title: String,
      creationDate: Date,
      appleWorkoutType: HKWorkoutActivityType,
      requiredEquipment: [Equipment],
      steps: [WorkoutStep]
    ) {
      self.id = id
      self.title = title
      self.creationDate = creationDate
      self.rawAppleWorkoutType = "\(appleWorkoutType.rawValue)"
      self.rawRequiredEquipment = requiredEquipment.map { $0.rawValue }
      self.steps = steps
    }
  }
}

public extension SchemaV12.WorkoutTemplate {
  enum Equipment: String, CaseIterable, Codable, Identifiable {
    case dumbbells
    case barbell
    case kettlebell
    case batBell
    case chinUpBar
    case treadmill
    case stationaryBike
    case bike
    case elliptical
    case rowingMachine
    case skiMachine
    case yogaMat
    case resistanceBand
    case weightedVest

    public var id: Self { self }
  }
}
