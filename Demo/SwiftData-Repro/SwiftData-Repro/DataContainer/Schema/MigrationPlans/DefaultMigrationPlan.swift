//
//  DefaultMigrationPlan.swift
//  SwiftData-Repro
//
//  Created by Zach Radford on 2025-03-24.
//

import Foundation
import SwiftData

// TODO: update this
// CURRENT SCHEMA
let currentSchema: VersionedSchema.Type = SchemaV5.self

enum DefaultMigrationPlan: SchemaMigrationPlan {
  public static var schemas: [any VersionedSchema.Type] {
    [
      SchemaV5.self,
      SchemaV6.self,
      SchemaV7.self,
      SchemaV8.self,
      SchemaV9.self
    ]
  }

  public static var stages: [MigrationStage] {
    [
      migrateV5ToV6,
      migrateV6ToV7,
      migrateV7ToV8,
      // migrateV8ToV9
    ]
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

//  private static var migrateV8ToV9: MigrationStage {
//    .custom(
//      fromVersion: SchemaV8.self,
//      toVersion: SchemaV9.self,
//      willMigrate: nil,
//      didMigrate: { context in
//        do {
//          try context.transaction {
//            let logs = try context.fetch(FetchDescriptor<SchemaV9.FoodItemLog>())
//
//            for log in logs {
//              // Move the serving amount from the log to the serving, since that is what the UI now works with.
//              if log.hasSingleServing {
//                guard let serving = log.firstFoodItemServing else { continue }
//
//                serving.numberOfServings = log.numberOfServings
//                log.numberOfServings = 1
//              }
//            }
//            try context.save()
//          }
//        } catch {
//          print("Migration Failed: \(error)")
//          throw error
//        }
//      }
//    )
//  }
}
