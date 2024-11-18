//
//  FoodItemLogV2.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-18.
//

import SwiftData

// https://www.hackingwithswift.com/books/ios-swiftui/syncing-swiftdata-with-cloudkit
// For CloudKit sync to work, all properties must be optional or have default values, and all relationship must be optional.

extension SchemaV2 {
    @Model
    public final class FoodItemLog: Identifiable, Hashable {
        public var id: String = ""
        public var date: Date = Date.distantPast
        public var numberOfServings: Double = 0
        public var foodItem: FoodItem?

        public init(
            id: String,
            date: Date,
            numberOfServings: Double,
            foodItem: FoodItem
        ) {
            self.id = id
            self.date = date
            self.numberOfServings = numberOfServings
            self.foodItem = foodItem
        }
    }
}
