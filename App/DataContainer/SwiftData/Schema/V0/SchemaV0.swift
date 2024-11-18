//
//  SchemaV0.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-16.
//

import Foundation
@preconcurrency import SwiftData

public enum SchemaV0: VersionedSchema {
    public static let versionIdentifier = Schema.Version(0, 0, 0)

    public static let models: [any PersistentModel.Type] = [
        SchemaV0.BowelMovement.self,
        SchemaV0.Habit.self
    ]
}
