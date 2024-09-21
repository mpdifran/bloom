//
//  SchemaV1.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-20.
//

import Foundation
import SwiftData

public enum SchemaV1: VersionedSchema {
    public static var versionIdentifier = Schema.Version(1, 0, 0)

    public static var models: [any PersistentModel.Type] = [
        SchemaV0.BowelMovement.self,
        SchemaV1.Habit.self
    ]
}
