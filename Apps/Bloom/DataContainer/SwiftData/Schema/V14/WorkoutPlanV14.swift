//
//  WorkoutPlanV14.swift
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
  public final class WorkoutPlan: Identifiable, Hashable {
    public var id: String
    public var title: String
    public var summary: String
    public var creationDate: Date
    public var rawRequiredEquipment: [String]

    @Relationship public var sets: [WorkoutSet]? = []

    public init(
      id: String,
      title: String,
      summary: String,
      creationDate: Date,
      requiredEquipment: [Equipment],
      sets: [WorkoutSet] = []
    ) {
      self.id = id
      self.title = title
      self.summary = summary
      self.creationDate = creationDate
      self.rawRequiredEquipment = requiredEquipment.map { $0.rawValue }
      self.sets = sets
    }
  }
}
