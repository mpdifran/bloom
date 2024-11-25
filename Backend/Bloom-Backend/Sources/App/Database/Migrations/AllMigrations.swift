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
    FoodItemRecord.Create()
]
