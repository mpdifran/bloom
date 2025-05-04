//
//  SchemaV14.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-04.
//

import Foundation
@preconcurrency import SwiftData

public enum SchemaV14: VersionedSchema {
  public static let versionIdentifier = Schema.Version(14, 0, 0)

  public static let models: [any PersistentModel.Type] = [
    SchemaV0.BowelMovement.self,
    SchemaV11.Habit.self,
    SchemaV9.FoodItemRecord.self,
    SchemaV9.FoodItemLog.self,
    SchemaV9.FoodItemServing.self,
    SchemaV9.MealRecord.self,
    SchemaV9.MealItemRecord.self,
    SchemaV10.ChatMessage.self,
    SchemaV14.WorkoutPlan.self,
    SchemaV14.WorkoutSet.self,
    SchemaV14.WorkoutExercise.self
  ]
}
