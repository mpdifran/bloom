//
//  FoodItemRecordV4.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-25.
//

import SwiftData

// https://www.hackingwithswift.com/books/ios-swiftui/syncing-swiftdata-with-cloudkit
// For CloudKit sync to work, all properties must be optional or have default values, and all relationship must be optional.

extension SchemaV4 {
    @Model
    public final class FoodItemRecord: Identifiable, Hashable {
        public var id: String = ""
        public var name: String = ""
        public var brandName: String = ""
        public var flavour: String = ""
        public var calories: Double = 0.0
        public var protein: Double = 0.0
        public var carbohydrates: Double = 0.0
        public var fat: Double = 0.0
        public var servingName: String?
        public var servingUnitString: String?
        public var servingValue: Double?
        public var ingredients: String?
        public var category: Category?
        public var isVerified: Bool = false

        @Relationship(deleteRule: .cascade, inverse: \FoodItemLog.foodItem)
        public var logs: [FoodItemLog]?

        public init(
            id: String,
            name: String,
            brandName: String,
            flavour: String,
            calories: Double,
            protein: Double,
            carbohydrates: Double,
            fat: Double,
            servingName: String?,
            servingUnitString: String?,
            servingValue: Double?,
            ingredients: String?,
            category: Category?,
            isVerified: Bool,
            logs: [FoodItemLog]
        ) {
            self.id = id
            self.name = name
            self.brandName = brandName
            self.flavour = flavour
            self.calories = calories
            self.protein = protein
            self.carbohydrates = carbohydrates
            self.fat = fat
            self.servingName = servingName
            self.servingUnitString = servingUnitString
            self.servingValue = servingValue
            self.ingredients = ingredients
            self.category = category
            self.isVerified = isVerified
            self.logs = logs
        }
    }
}

public extension SchemaV4.FoodItemRecord {
    enum Category: String, Hashable, Codable, Sendable {
        case generic
        case fastfood
        case restaurant
        case branded
        case aiGenerated
    }
}
