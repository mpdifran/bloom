//
//  SchemaV4.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-25.
//

import Foundation
@preconcurrency import SwiftData

public enum SchemaV4: VersionedSchema {
    public static let versionIdentifier = Schema.Version(4, 0, 0)

    public static let models: [any PersistentModel.Type] = [
        SchemaV0.BowelMovement.self,
        SchemaV2.Habit.self,
        SchemaV4.FoodItemRecord.self,
        SchemaV4.FoodItemLog.self
    ]
}
