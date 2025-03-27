//
//  Migration.swift
//  SwiftData-Repro
//
//  Created by Zach Radford on 2025-03-27.
//

import SwiftData

// MARK: - V5

let currentSchema: VersionedSchema.Type = SchemaV5.self

public typealias FoodItemRecord = SchemaV5.FoodItemRecord
public typealias FoodItemLog = SchemaV5.FoodItemLog

// MARK: - V6
/// Note:  Need to remove 'logs: []' from TextData in ContentView so the next migration builds.

//let currentSchema: VersionedSchema.Type = SchemaV6.self

//public typealias FoodItemRecord = SchemaV6.FoodItemRecord
//public typealias FoodItemLog = SchemaV6.FoodItemLog
//public typealias FoodItemServing = SchemaV6.FoodItemServing
//public typealias MealItemRecord = SchemaV6.MealItemRecord
//public typealias MealRecord = SchemaV6.MealRecord

// MARK: - V7

//let currentSchema: VersionedSchema.Type = SchemaV7.self

//public typealias FoodItemRecord = SchemaV7.FoodItemRecord
//public typealias FoodItemLog = SchemaV7.FoodItemLog
//public typealias FoodItemServing = SchemaV7.FoodItemServing
//public typealias MealItemRecord = SchemaV7.MealItemRecord
//public typealias MealRecord = SchemaV7.MealRecord

// MARK: - V8

//let currentSchema: VersionedSchema.Type = SchemaV8.self

//public typealias FoodItemRecord = SchemaV8.FoodItemRecord
//public typealias FoodItemLog = SchemaV8.FoodItemLog
//public typealias FoodItemServing = SchemaV8.FoodItemServing
//public typealias MealItemRecord = SchemaV8.MealItemRecord
//public typealias MealRecord = SchemaV8.MealRecord

// MARK: - V9

//let currentSchema: VersionedSchema.Type = SchemaV9.self

//public typealias FoodItemRecord = SchemaV9.FoodItemRecord
//public typealias FoodItemLog = SchemaV9.FoodItemLog
//public typealias FoodItemServing = SchemaV9.FoodItemServing
//public typealias MealItemRecord = SchemaV9.MealItemRecord
//public typealias MealRecord = SchemaV9.MealRecord
