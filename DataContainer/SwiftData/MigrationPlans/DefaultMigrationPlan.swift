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
//            SchemaV1.self
        ]
    }

    public static var stages: [MigrationStage] {
        [
//            migrateV0ToV1
        ]
    }

    static var migrateV0ToV1: MigrationStage {
        MigrationStage.lightweight(
            fromVersion: SchemaV0.self,
            toVersion: SchemaV1.self
        )
    }
}
