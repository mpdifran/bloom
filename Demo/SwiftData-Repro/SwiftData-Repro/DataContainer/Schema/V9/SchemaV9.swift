//
//  SchemaV8.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-12.
//

import Foundation
@preconcurrency import SwiftData

public enum SchemaV9: VersionedSchema {
  public static let versionIdentifier = Schema.Version(9, 0, 0)

  public static let models: [any PersistentModel.Type] = [
    SchemaV2.Habit.self,
    SchemaV9.FoodItemRecord.self,
    SchemaV9.FoodItemLog.self,
    SchemaV9.FoodItemServing.self,
    SchemaV9.MealRecord.self,
    SchemaV9.MealItemRecord.self,
  ]
}
