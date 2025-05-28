//
//  Migration.swift
//  SwiftData-Repro
//
//  Created by Zach Radford on 2025-03-27.
//

import SwiftData

// This doesn't change across migrations
public typealias Habit = SchemaV2.Habit

// MARK: - V5

let currentSchema: VersionedSchema.Type = SchemaV5.self

let currentSchemas: [any VersionedSchema.Type] = [
  SchemaV2.self,
  SchemaV5.self
]

let currentStages: [MigrationStage] = []

public typealias FoodItemRecord = SchemaV5.FoodItemRecord
public typealias FoodItemLog = SchemaV5.FoodItemLog

// MARK: - V6

// let currentSchema: VersionedSchema.Type = SchemaV6.self
//
// let currentSchemas: [any VersionedSchema.Type] = [
//  SchemaV2.self,
//  SchemaV5.self,
//  SchemaV6.self,
// ]
//
// let currentStages: [MigrationStage] = [
//  DefaultMigrationPlan.migrateV5ToV6,
// ]
//
// public typealias FoodItemRecord = SchemaV6.FoodItemRecord
// public typealias FoodItemLog = SchemaV6.FoodItemLog
// public typealias FoodItemServing = SchemaV6.FoodItemServing
// public typealias MealItemRecord = SchemaV6.MealItemRecord
// public typealias MealRecord = SchemaV6.MealRecord

// MARK: - V7

// let currentSchema: VersionedSchema.Type = SchemaV7.self
//
// let currentSchemas: [any VersionedSchema.Type] = [
//  SchemaV2.self,
//  SchemaV5.self,
//  SchemaV6.self,
//  SchemaV7.self,
// ]
//
// let currentStages: [MigrationStage] = [
//  DefaultMigrationPlan.migrateV5ToV6,
//  DefaultMigrationPlan.migrateV6ToV7,
// ]
//
// public typealias FoodItemRecord = SchemaV7.FoodItemRecord
// public typealias FoodItemLog = SchemaV7.FoodItemLog
// public typealias FoodItemServing = SchemaV7.FoodItemServing
// public typealias MealItemRecord = SchemaV7.MealItemRecord
// public typealias MealRecord = SchemaV7.MealRecord

// MARK: - V8

// let currentSchema: VersionedSchema.Type = SchemaV8.self
//
// let currentSchemas: [any VersionedSchema.Type] = [
//  SchemaV2.self,
//  SchemaV5.self,
//  SchemaV6.self,
//  SchemaV7.self,
//  SchemaV8.self,
// ]
//
// let currentStages: [MigrationStage] = [
//  DefaultMigrationPlan.migrateV5ToV6,
//  DefaultMigrationPlan.migrateV6ToV7,
//  DefaultMigrationPlan.migrateV7ToV8,
// ]
//
// public typealias FoodItemRecord = SchemaV8.FoodItemRecord
// public typealias FoodItemLog = SchemaV8.FoodItemLog
// public typealias FoodItemServing = SchemaV8.FoodItemServing
// public typealias MealItemRecord = SchemaV8.MealItemRecord
// public typealias MealRecord = SchemaV8.MealRecord

// MARK: - V9

// let currentSchema: VersionedSchema.Type = SchemaV9.self
//
// let currentSchemas: [any VersionedSchema.Type] = [
//  SchemaV2.self,
//  SchemaV5.self,
//  SchemaV6.self,
//  SchemaV7.self,
//  SchemaV8.self,
//  SchemaV9.self,
// ]
//
// let currentStages: [MigrationStage] = [
//  DefaultMigrationPlan.migrateV5ToV6,
//  DefaultMigrationPlan.migrateV6ToV7,
//  DefaultMigrationPlan.migrateV7ToV8,
//  DefaultMigrationPlan.migrateV8ToV9,
// ]
//
// public typealias FoodItemRecord = SchemaV9.FoodItemRecord
// public typealias FoodItemLog = SchemaV9.FoodItemLog
// public typealias FoodItemServing = SchemaV9.FoodItemServing
// public typealias MealItemRecord = SchemaV9.MealItemRecord
// public typealias MealRecord = SchemaV9.MealRecord
