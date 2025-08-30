//
//  DefaultMigrationPlan.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-16.
//

import SwiftData

// CURRENT SCHEMA
let currentSchema: VersionedSchema.Type = SchemaV25.self

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
      SchemaV9.self,
      SchemaV10.self,
      SchemaV11.self,
      SchemaV12.self,
      SchemaV13.self,
      SchemaV14.self,
      SchemaV15.self,
      SchemaV16.self,
      SchemaV17.self,
      SchemaV18.self,
      SchemaV19.self,
      SchemaV20.self,
      SchemaV21.self,
      SchemaV22.self,
      SchemaV23.self,
      SchemaV24.self,
      SchemaV25.self
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
      migrateV8ToV9,
      migrateV9ToV10,
      migrateV10ToV11,
      migrateV11ToV12,
      migrateV12ToV13,
      migrateV13ToV14,
      migrateV14ToV15,
      migrateV15ToV16,
      migrateV16ToV17,
      migrateV17ToV18,
      migrateV18ToV19,
      migrateV19ToV20,
      migrateV20ToV21,
      migrateV21ToV22,
      migrateV22ToV23,
      migrateV23ToV24,
      migrateV24ToV25
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
          try context.transaction {
            let logs = try context.fetch(FetchDescriptor<SchemaV7.FoodItemLog>())

            for log in logs {
              log.mealRawValue = log.meal.rawValue
            }
            try context.save()
          }
        } catch {
          print("Migration Failed: \(error)")
          throw error
        }
      },
      didMigrate: nil
    )
  }

  private static var migrateV8ToV9: MigrationStage {
    .custom(
      fromVersion: SchemaV8.self,
      toVersion: SchemaV9.self,
      willMigrate: nil,
      didMigrate: { context in
        do {
          try context.transaction {
            let logs = try context.fetch(FetchDescriptor<SchemaV9.FoodItemLog>())

            for log in logs {
              // Move the serving amount from the log to the serving, since that is what the UI now works with.
              if log.hasSingleServing {
                guard let serving = log.firstFoodItemServing else { continue }

                serving.numberOfServings = log.numberOfServings
                log.numberOfServings = 1
              }
            }
            try context.save()
          }
        } catch {
          print("Migration Failed: \(error)")
          throw error
        }
      }
    )
  }

  private static var migrateV9ToV10: MigrationStage {
    .lightweight(
      fromVersion: SchemaV9.self,
      toVersion: SchemaV10.self
    )
  }

  private static var migrateV10ToV11: MigrationStage {
    .custom(
      fromVersion: SchemaV10.self,
      toVersion: SchemaV11.self,
      willMigrate: nil,
      didMigrate: { context in
        do {
          try context.savingTransaction {
            let habits = try context.fetch(FetchDescriptor<SchemaV11.Habit>())

            for habit in habits {
              habit.timePeriod = .daily
            }
          }
        } catch {
          print("Migration Failed: \(error)")
          throw error
        }
      }
    )
  }

  private static var migrateV11ToV12: MigrationStage {
    .lightweight(
      fromVersion: SchemaV11.self,
      toVersion: SchemaV12.self
    )
  }

  private static var migrateV12ToV13: MigrationStage {
    .lightweight(
      fromVersion: SchemaV12.self,
      toVersion: SchemaV13.self
    )
  }

  private static var migrateV13ToV14: MigrationStage {
    .lightweight(
      fromVersion: SchemaV13.self,
      toVersion: SchemaV14.self
    )
  }

  private static var migrateV14ToV15: MigrationStage {
    .lightweight(
      fromVersion: SchemaV14.self,
      toVersion: SchemaV15.self
    )
  }

  private static var migrateV15ToV16: MigrationStage {
    .lightweight(
      fromVersion: SchemaV15.self,
      toVersion: SchemaV16.self
    )
  }

  private static var migrateV16ToV17: MigrationStage {
    .lightweight(
      fromVersion: SchemaV16.self,
      toVersion: SchemaV17.self
    )
  }

  private static var migrateV17ToV18: MigrationStage {
    .lightweight(
      fromVersion: SchemaV17.self,
      toVersion: SchemaV18.self
    )
  }

  private static var migrateV18ToV19: MigrationStage {
    .lightweight(
      fromVersion: SchemaV18.self,
      toVersion: SchemaV19.self
    )
  }

  private static var migrateV19ToV20: MigrationStage {
    .lightweight(
      fromVersion: SchemaV19.self,
      toVersion: SchemaV20.self
    )
  }

  private static var migrateV20ToV21: MigrationStage {
    .lightweight(
      fromVersion: SchemaV20.self,
      toVersion: SchemaV21.self
    )
  }

  private static var migrateV21ToV22: MigrationStage {
    .lightweight(
      fromVersion: SchemaV21.self,
      toVersion: SchemaV22.self
    )
  }

  private static var migrateV22ToV23: MigrationStage {
    .lightweight(
      fromVersion: SchemaV22.self,
      toVersion: SchemaV23.self
    )
  }

  private static var migrateV23ToV24: MigrationStage {
    .lightweight(
      fromVersion: SchemaV23.self,
      toVersion: SchemaV24.self
    )
  }

  private static var migrateV24ToV25: MigrationStage {
    .lightweight(
      fromVersion: SchemaV24.self,
      toVersion: SchemaV25.self
    )
  }
}
