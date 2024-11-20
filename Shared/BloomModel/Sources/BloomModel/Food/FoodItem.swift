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

    /// This is the nutrients per serving in the food item.
    /// To get the total nutrients, multiple by the quantity of servings.
    public let nutrients: [Nutrient]

    /// The serving name is what you might see on a nutrition label (e.g. 1 breast, 1 package, 24 chips)
    public let servingName: String?

    /// The serving quantity is some numerical breakdown of the serving name, such as
    /// {
    ///    unit: "g" (like grams)
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
        nutrients: [Nutrient],
        servingName: String?,
        servingQuantity: Quantity?,
        ingredients: String?,
        isVerified: Bool
    ) {
        self.id = id
        self.name = name
        self.brandName = brandName
        self.flavour = flavour
        self.nutrients = nutrients
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
    struct Nutrient: Codable, Identifiable, Sendable, Hashable {
        public var id: Kind { kind }

        public let kind: Kind
        public let quantity: Quantity

        public init(
            kind: Kind,
            quantity: Quantity
        ) {
            self.kind = kind
            self.quantity = quantity
        }
    }
}

public extension FoodItem.Nutrient {
    enum Kind: String, Codable, Sendable, Hashable {
        case protein
        case carbohydrates
        case fat
        case calories
    }
}

public extension FoodItem.Nutrient.Kind {

    var name: String {
        switch self {
        case .protein: return "Protein"
        case .carbohydrates: return "Carbohydrates"
        case .fat: return "Fat"
        case .calories: return "Calories"
        }
    }
}
