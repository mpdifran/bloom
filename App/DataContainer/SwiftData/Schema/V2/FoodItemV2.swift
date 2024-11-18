//
//  FoodItemV2.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-18.
//

import SwiftData

extension SchemaV2 {
    @Model
    public final class FoodItem: Identifiable, Hashable {
        public var id: String = ""
        public var name: String = ""
        public var brandName: String = ""
        public var calories: Double = 0.0
        public var protein: Double = 0.0
        public var carbohydrates: Double = 0.0
        public var fat: Double = 0.0
        public var servingName: String?
        public var servingUnitString: String?
        public var servingValue: Double?
        public var ingredients: String?

        @Relationship(deleteRule: .cascade, inverse: \FoodItemLog.foodItem)
        public var logs: [FoodItemLog]

        public init(
            id: String,
            name: String,
            brandName: String,
            calories: Double,
            protein: Double,
            carbohydrates: Double,
            fat: Double,
            servingName: String?,
            servingUnitString: String?,
            servingValue: Double?,
            ingredients: String?,
            logs: [FoodItemLog]
        ) {
            self.id = id
            self.name = name
            self.brandName = brandName
            self.calories = calories
            self.protein = protein
            self.carbohydrates = carbohydrates
            self.fat = fat
            self.servingName = servingName
            self.servingUnitString = servingUnitString
            self.servingValue = servingValue
            self.ingredients = ingredients
            self.logs = logs
        }
    }
}
