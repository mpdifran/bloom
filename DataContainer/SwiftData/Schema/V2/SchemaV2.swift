//
//  SchemaV2.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-02.
//

import Foundation
import SwiftData

public enum SchemaV2: VersionedSchema {
    public static var versionIdentifier = Schema.Version(2, 0, 0)

    public static var models: [any PersistentModel.Type] = [
        SchemaV0.BowelMovement.self,
        SchemaV2.Habit.self
    ]
}
