//
//  SchemaV6.swift
//  Supplements
//
//  Created by Zach Radford on 2025-01-18.
//

import Foundation
@preconcurrency import SwiftData

public enum SchemaV6: VersionedSchema {
    public static let versionIdentifier = Schema.Version(6, 0, 0)

    public static let models: [any PersistentModel.Type] = [
        SchemaV0.BowelMovement.self,
        SchemaV2.Habit.self,
        SchemaV5.FoodItemRecord.self,
        SchemaV6.FoodItemLog.self,
        SchemaV6.MealRecord.self,
        SchemaV6.MealItem.self,
    ]
}
