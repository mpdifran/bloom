//
//  DefaultMigrationPlan.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-16.
//

import SwiftData

public enum DefaultMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [
            SchemaV0.self
        ]
    }

    public static var stages: [MigrationStage] {
        [
        ]
    }
}
