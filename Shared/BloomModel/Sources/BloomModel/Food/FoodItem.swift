//
//  Food.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2024-11-10.
//

import Foundation
import AppFoundations

public final class FoodItemIdentifier: Identifier, Codable, @unchecked Sendable { }

public struct FoodItem: Codable, Identifiable, Sendable, Hashable {
    public let id: FoodItemIdentifier
    public let name: String
    public let brandName: String?
    public let flavour: String?

    public let calories: Quantity?
    public let protein: Quantity?
    public let carbohydrates: Quantity?
    public let fat: Quantity?

    /// The serving name is what you might see on a nutrition label (e.g. 1 breast, 1 package, 24 chips)
    public let servingName: String?

    /// The serving quantity is some numerical breakdown of the serving name, such as
    /// {
    ///    unit: "g" (like grams),
    ///    value: 100
    /// }
    public let servingQuantity: Quantity?
    public let ingredients: String?
    public let isVerified: Bool

    public init(
        id: FoodItemIdentifier,
        name: String,
        brandName: String?,
        flavour: String?,
        calories: Quantity?,
        protein: Quantity?,
        carbohydrates: Quantity?,
        fat: Quantity?,
        servingName: String?,
        servingQuantity: Quantity?,
        ingredients: String?,
        isVerified: Bool
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
        self.servingQuantity = servingQuantity
        self.ingredients = ingredients
        self.isVerified = isVerified
    }
}

public extension FoodItem {
    struct Quantity: Codable, Sendable, Hashable {
        public let value: Double
        public let unit: String

        public init(
            value: Double,
            unit: String
        ) {
            self.value = value
            self.unit = unit
        }
    }
}

public extension FoodItem {

    var displayServing: String {
        var result = ""

        if let name = servingName {
            result = name
        }

        if let quantity = servingQuantity {
            result += " (\(quantity.value.formatted()) \(quantity.unit))"
        }

        return result
    }
}
