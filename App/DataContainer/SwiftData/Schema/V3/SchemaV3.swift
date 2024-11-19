//
//  SchemaV3.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-19.
//

import Foundation
@preconcurrency import SwiftData

public enum SchemaV3: VersionedSchema {
    public static let versionIdentifier = Schema.Version(3, 0, 0)

    public static let models: [any PersistentModel.Type] = [
        SchemaV0.BowelMovement.self,
        SchemaV2.Habit.self,
        SchemaV3.FoodItem.self,
        SchemaV3.FoodItemLog.self
    ]
}
