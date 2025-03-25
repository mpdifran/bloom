//
//  SchemaV7.swift
//  Bloom
//
//  Created by Zach Radford on 2025-02-02.
//

import Foundation
@preconcurrency import SwiftData

public enum SchemaV7: VersionedSchema {
  public static let versionIdentifier = Schema.Version(7, 0, 0)

  public static let models: [any PersistentModel.Type] = [
    SchemaV0.BowelMovement.self,
    SchemaV2.Habit.self,
    SchemaV7.FoodItemRecord.self,
    SchemaV7.FoodItemLog.self,
    SchemaV7.FoodItemServing.self,
    SchemaV7.MealRecord.self,
    SchemaV7.MealItemRecord.self,
  ]
}
