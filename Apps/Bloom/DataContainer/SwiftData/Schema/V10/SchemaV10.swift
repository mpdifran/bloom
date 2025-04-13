//
//  SchemaV10.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-13.
//

import Foundation
@preconcurrency import SwiftData

public enum SchemaV10: VersionedSchema {
  public static let versionIdentifier = Schema.Version(10, 0, 0)

  public static let models: [any PersistentModel.Type] = [
    SchemaV0.BowelMovement.self,
    SchemaV2.Habit.self,
    SchemaV9.FoodItemRecord.self,
    SchemaV9.FoodItemLog.self,
    SchemaV9.FoodItemServing.self,
    SchemaV9.MealRecord.self,
    SchemaV9.MealItemRecord.self,
    SchemaV10.ChatMessage.self
  ]
}
