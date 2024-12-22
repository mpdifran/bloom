//
//  AllMigrations.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-11.
//

import Foundation
import Fluent

let allMigrations: [Migration] = [
    EnablePgTrgmMigration(),
    FoodItemRecord.Create(),
    FoodItemRecord.AddNutrients(),
    FoodItemRecord.FixNutritionFieldTypes(),
    FoodItemRecord.AddSourceProperty(),
    FoodItemRecord.AddNeedsAIProcessingState(),
    FoodItemRecord.AddNeedsMoreInfoAndNotes(),
    User.Create(),
    UserToken.Create(),
]
