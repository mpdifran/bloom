//
//  DefaultMigrationPlan.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-16.
//

import SwiftData

// CURRENT SCHEMA
let currentSchema: VersionedSchema.Type = SchemaV7.self

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
        let logs = try context.fetch(FetchDescriptor<SchemaV6.FoodItemLog>())

        for log in logs {
//          log.foodItemServings = [
//            SchemaV6.FoodItemServing(
//              id: UUID().uuidString,
//              numberOfServings: 1,
//              foodItem: log.foodItem
//            )
//          ]
          let newLog = log
          newLog.foodItemServings = [
            SchemaV6.FoodItemServing(
              id: UUID().uuidString,
              numberOfServings: 1,
              foodItem: log.foodItem
            )
          ]
          context.delete(log)
          context.insert(newLog)
//          guard let foodItem = log.foodItem else {
//            context.delete(log)
//            continue
//          }
//
//          let newFoodItem = SchemaV7.FoodItemRecord(
//            id: foodItem.id,
//            name: foodItem.name,
//            brandName: foodItem.brandName,
//            flavour: foodItem.flavour,
//            rawCountry: foodItem.rawCountry,
//            calories: foodItem.calories,
//            protein: foodItem.protein,
//            carbohydrates: foodItem.carbohydrates,
//            fat: foodItem.fat,
//            saturatedFat: foodItem.saturatedFat,
//            transFat: foodItem.transFat,
//            polyunsaturatedFat: foodItem.polyunsaturatedFat,
//            monounsaturatedFat: foodItem.monounsaturatedFat,
//            fiber: foodItem.fiber,
//            sugar: foodItem.sugar,
//            cholesterol: foodItem.cholesterol,
//            sodium: foodItem.sodium,
//            calcium: foodItem.calcium,
//            iron: foodItem.iron,
//            potassium: foodItem.potassium,
//            magnesium: foodItem.magnesium,
//            zinc: foodItem.zinc,
//            vitaminA: foodItem.vitaminA,
//            vitaminB6: foodItem.vitaminB6,
//            vitaminB12: foodItem.vitaminB12,
//            vitaminC: foodItem.vitaminC,
//            vitaminD: foodItem.vitaminD,
//            vitaminE: foodItem.vitaminE,
//            servingName: foodItem.servingName,
//            servingUnitString: foodItem.servingUnitString,
//            servingValue: foodItem.servingValue,
//            ingredients: foodItem.ingredients,
//            category: foodItem.category?.toV7(),
//            isVerified: foodItem.isVerified
//          )
//          let newLog = SchemaV7.FoodItemLog(
//            id: UUID().uuidString,
//            date: log.date,
//            meal: log.meal.toV7(),
//            numberOfServings: log.numberOfServings,
//            foodItem: newFoodItem
//          )
//
//          context.insert(newFoodItem)
//          context.insert(newLog)
//
//          context.delete(log)
        }

        try context.save()
      },
      didMigrate: nil
    )
  }
}
