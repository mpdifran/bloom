//
//  DefaultMigrationPlan.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-16.
//

import SwiftData

// CURRENT SCHEMA
let currentSchema: VersionedSchema.Type = SchemaV9.self

public enum DefaultMigrationPlan: SchemaMigrationPlan {
  public static var schemas: [any VersionedSchema.Type] {
    [
      SchemaV0.self,
      SchemaV1.self,
      SchemaV2.self,
      SchemaV3.self,
      SchemaV4.self,
      SchemaV5.self,
      SchemaV6.self,
      SchemaV7.self,
      SchemaV8.self,
      SchemaV9.self
    ]
  }

  public static var stages: [MigrationStage] {
    [
      migrateV0ToV1,
      migrateV1ToV2,
      migrateV2toV3,
      migrateV3toV4,
      migrateV4toV5,
      migrateV5ToV6,
      migrateV6ToV7,
      migrateV7ToV8,
      migrateV8ToV9
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

  private static var migrateV3toV4: MigrationStage {
    .lightweight(
      fromVersion: SchemaV3.self,
      toVersion: SchemaV4.self
    )
  }

  private static var migrateV4toV5: MigrationStage {
    .lightweight(
      fromVersion: SchemaV4.self,
      toVersion: SchemaV5.self
    )
  }

  private static var migrateV5ToV6: MigrationStage {
    .lightweight(
      fromVersion: SchemaV5.self,
      toVersion: SchemaV6.self
    )
  }

  private static var migrateV6ToV7: MigrationStage {
    .custom(
      fromVersion: SchemaV6.self,
      toVersion: SchemaV7.self,
      willMigrate: { context in
        do {
          let logs = try context.fetch(FetchDescriptor<SchemaV6.FoodItemLog>())

          for log in logs {
            let serving = SchemaV6.FoodItemServing(
              id: UUID().uuidString,
              numberOfServings: 1,
              foodItem: log.foodItem
            )
            serving.foodItemLog = log

            context.insert(serving)
            if log.foodItemServings == nil {
              log.foodItemServings = []
            }
            log.foodItemServings?.append(serving)
          }

          try context.save()
        } catch {
          print("Migration Failed: \(error)")
          throw error
        }
      },
      didMigrate: nil
    )
  }

  private static var migrateV7ToV8: MigrationStage {
    .custom(
      fromVersion: SchemaV7.self,
      toVersion: SchemaV8.self,
      willMigrate: { context in
        do {
          let logs = try context.fetch(FetchDescriptor<SchemaV7.FoodItemLog>())

          for log in logs {
            log.mealRawValue = log.meal.rawValue
          }
          try context.save()
        } catch {
          print("Migration Failed: \(error)")
          throw error
        }
      },
      didMigrate: nil
    )
  }

  private static var migrateV8ToV9: MigrationStage {
    .lightweight(
      fromVersion: SchemaV8.self,
      toVersion: SchemaV9.self
    )
  }
}
