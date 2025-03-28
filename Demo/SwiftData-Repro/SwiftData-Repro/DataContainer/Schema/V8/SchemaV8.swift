//
//  SchemaV8.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-12.
//

import Foundation
@preconcurrency import SwiftData

public enum SchemaV8: VersionedSchema {
  public static let versionIdentifier = Schema.Version(8, 0, 0)

  public static let models: [any PersistentModel.Type] = [
    SchemaV2.Habit.self,
    SchemaV8.FoodItemRecord.self,
    SchemaV8.FoodItemLog.self,
    SchemaV8.FoodItemServing.self,
    SchemaV8.MealRecord.self,
    SchemaV8.MealItemRecord.self,
  ]
}
