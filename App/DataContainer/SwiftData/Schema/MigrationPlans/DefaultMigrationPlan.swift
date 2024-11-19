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
            SchemaV0.self,
            SchemaV1.self,
            SchemaV2.self,
            SchemaV3.self
        ]
    }

    public static var stages: [MigrationStage] {
        [
            migrateV0ToV1,
            migrateV1ToV2,
            migrateV2toV3
        ]
    }

    private static var migrateV0ToV1: MigrationStage {
        MigrationStage.custom(
            fromVersion: SchemaV0.self,
            toVersion: SchemaV1.self,
            willMigrate: { context in
                let habits = try context.fetch(FetchDescriptor<SchemaV0.Habit>())

                for habit in habits {

                    let newHabit = SchemaV1.Habit(
                        targetMetric: habit.targetMetric ?? .none,
                        value: habit.value,
                        unitString: habit.unitString,
                        startDate: habit.startDate,
                        endDate: habit.endDate,
                        isSuggested: habit.isSuggested,
                        isUserEdited: habit.isUserEdited,
                        vitalKind: habit.vitalKind,
                        context: habit.context
                    )
                    context.insert(newHabit)
                    context.delete(habit)
                }

                try context.save()
            },
            didMigrate: nil
        )
    }

    private static var migrateV1ToV2: MigrationStage {
        .lightweight(
            fromVersion: SchemaV1.self,
            toVersion: SchemaV2.self
        )
    }

    private static var migrateV2toV3: MigrationStage {
        .lightweight(
            fromVersion: SchemaV2.self,
            toVersion: SchemaV3.self
        )
    }
}
