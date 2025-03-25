//
//  FoodItemLogV4.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-25.
//

import Foundation
import SwiftData

// https://www.hackingwithswift.com/books/ios-swiftui/syncing-swiftdata-with-cloudkit
// For CloudKit sync to work, all properties must be optional or have default values, and all relationship must be optional.

extension SchemaV4 {
    @Model
    public final class FoodItemLog: Identifiable, Hashable {
        public var id: String = ""
        public var date: Date = Date.distantPast
        public var meal: Meal = Meal.breakfast
        public var numberOfServings: Double = 0
        @Relationship public var foodItem: SchemaV4.FoodItemRecord? = nil

        public init(
            id: String,
            date: Date,
            meal: Meal,
            numberOfServings: Double,
            foodItem: SchemaV4.FoodItemRecord
        ) {
            self.id = id
            self.date = date
            self.meal = meal
            self.numberOfServings = numberOfServings
            self.foodItem = foodItem
        }
    }
}

public extension SchemaV4.FoodItemLog {
    enum Meal: String, Hashable, Sendable, Codable, CaseIterable, Identifiable {
        public var id: Self { self }

        case breakfast
        case lunch
        case dinner
        case snack
    }
}

public extension SchemaV4.FoodItemLog.Meal {
    var name: String {
        rawValue.capitalized
    }
}
