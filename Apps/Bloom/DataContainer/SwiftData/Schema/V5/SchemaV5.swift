//
//  SchemaV5.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-02.
//

import Foundation
@preconcurrency import SwiftData

public enum SchemaV5: VersionedSchema {
    public static let versionIdentifier = Schema.Version(5, 0, 0)

    public static let models: [any PersistentModel.Type] = [
        SchemaV0.BowelMovement.self,
        SchemaV2.Habit.self,
        SchemaV5.FoodItemRecord.self,
        SchemaV5.FoodItemLog.self
    ]
}
