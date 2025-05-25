//
//  SchemaV17.swift
//  Bloom
//
//  Created by Assistant on 2025-05-24.
//

import Foundation
@preconcurrency import SwiftData

public enum SchemaV17: VersionedSchema {
  public static let versionIdentifier = Schema.Version(17, 0, 0)

  public static let models: [any PersistentModel.Type] = [
    SchemaV17.BowelMovement.self,
    SchemaV11.Habit.self,
    SchemaV9.FoodItemRecord.self,
    SchemaV9.FoodItemLog.self,
    SchemaV9.FoodItemServing.self,
    SchemaV9.MealRecord.self,
    SchemaV9.MealItemRecord.self,
    SchemaV15.ChatMessage.self,
    SchemaV14.WorkoutPlan.self,
    SchemaV14.WorkoutSet.self,
    SchemaV14.WorkoutExercise.self
  ]
}