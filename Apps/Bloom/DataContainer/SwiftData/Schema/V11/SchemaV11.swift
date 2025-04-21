//
//  SchemaV11.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-20.
//

import Foundation
@preconcurrency import SwiftData

public enum SchemaV11: VersionedSchema {
  public static let versionIdentifier = Schema.Version(11, 0, 0)

  public static let models: [any PersistentModel.Type] = [
    SchemaV0.BowelMovement.self,
    SchemaV11.Habit.self,
    SchemaV9.FoodItemRecord.self,
    SchemaV9.FoodItemLog.self,
    SchemaV9.FoodItemServing.self,
    SchemaV9.MealRecord.self,
    SchemaV9.MealItemRecord.self,
    SchemaV10.ChatMessage.self
  ]
}
